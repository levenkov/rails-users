class OrderArchiveService
  Result = Struct.new(:success?, :error, keyword_init: true)

  def initialize(order, user)
    @order = order
    @user = user
  end

  def call
    unless @order.finished?
      return Result.new(success?: false, error: 'Order must be finished before archiving.')
    end

    unless @order.owner_id == @user.id
      return Result.new(success?: false, error: 'Only the order owner can archive.')
    end

    if @order.archived?
      return Result.new(success?: false, error: 'Order is already archived.')
    end

    participant_ids = @order.users.pluck(:id)
    pairs = participant_ids.combination(2).map { |a, b| [ a, b ].sort }

    pairs.each do |low_id, high_id|
      has_unarchived_prior = Order.joins(:users)
        .where(orders_users: { user_id: low_id })
        .where(id: Order.joins(:users).where(orders_users: { user_id: high_id }).select(:id))
        .where('orders.id < ?', @order.id)
        .where(archived_at: nil)
        .exists?

      if has_unarchived_prior
        return Result.new(success?: false, error: 'All previous shared orders must be archived first.')
      end
    end

    ActiveRecord::Base.transaction do
      pairs.each do |low_id, high_id|
        user_low = User.find(low_id)
        user_high = User.find(high_id)
        balance = UserPairBalanceCalculator.new(user_low, user_high).call

        UserPairBalance.create!(
          order: @order,
          user_low_id: low_id,
          user_high_id: high_id,
          balance: balance
        )
      end

      @order.update!(archived_at: Time.current)
    end

    Result.new(success?: true, error: nil)
  end
end
