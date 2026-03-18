class UserPairBalanceCalculator
  def initialize(user_a, user_b)
    @low_id, @high_id = [ user_a.id, user_b.id ].sort
  end

  def call
    balance = last_snapshot_balance
    balance += order_debts_since_snapshot
    balance += p2p_payments_since_snapshot
    balance
  end

  private

  def last_snapshot
    @last_snapshot ||= UserPairBalance
      .where(user_low_id: @low_id, user_high_id: @high_id)
      .joins(:order)
      .order('orders.id DESC')
      .first
  end

  def last_snapshot_balance
    last_snapshot&.balance || BigDecimal('0')
  end

  def orders_to_consider
    scope = Order.joins(:users)
      .where(orders_users: { user_id: @low_id })
      .where(id: Order.joins(:users).where(orders_users: { user_id: @high_id }).select(:id))

    if last_snapshot
      scope = scope.where('orders.id > ?', last_snapshot.order_id)
    end

    scope.distinct
  end

  def order_debts_since_snapshot
    total = BigDecimal('0')

    orders_to_consider.includes(order_items: :order_item_splits).find_each do |order|
      debts = OrderDebtCalculator.new(order).call
      debts.each do |debt|
        from_id, to_id = debt[:from_user_id], debt[:to_user_id]
        next unless [ from_id, to_id ].sort == [ @low_id, @high_id ]

        if to_id == @low_id
          total += debt[:amount]
        else
          total -= debt[:amount]
        end
      end
    end

    total
  end

  def p2p_payments_since_snapshot
    total = BigDecimal('0')
    scope = FinancialTransaction.where(
      sender_id: [ @low_id, @high_id ],
      receiver_id: [ @low_id, @high_id ]
    ).where('financial_transactions.sender_id != financial_transactions.receiver_id')

    if last_snapshot
      scope = scope.where('created_at > ?', last_snapshot.created_at)
    end

    scope.find_each do |ft|
      if ft.receiver_id == @low_id
        total -= ft.amount
      else
        total += ft.amount
      end
    end

    total
  end
end
