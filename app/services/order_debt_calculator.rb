class OrderDebtCalculator
  def initialize(order)
    @order = order
  end

  # Returns an array of { from_user_id:, to_user_id:, amount: }
  def call
    creditors = []
    debtors = []

    balances.each do |uid, balance|
      if balance > 0
        creditors << { user_id: uid, amount: balance }
      elsif balance < 0
        debtors << { user_id: uid, amount: -balance }
      end
    end

    creditors.sort_by! { |c| -c[:amount] }
    debtors.sort_by! { |d| -d[:amount] }

    result = []
    ci = 0
    di = 0

    while ci < creditors.length && di < debtors.length
      transfer = [ creditors[ci][:amount], debtors[di][:amount] ].min
      result << {
        from_user_id: debtors[di][:user_id],
        to_user_id: creditors[ci][:user_id],
        amount: transfer
      }
      creditors[ci][:amount] -= transfer
      debtors[di][:amount] -= transfer
      ci += 1 if creditors[ci][:amount].zero?
      di += 1 if debtors[di][:amount].zero?
    end

    result
  end

  private

  def balances
    shares = user_shares
    payments = user_payments

    user_ids = (shares.keys + payments.keys).uniq
    zero = BigDecimal('0')
    user_ids.to_h { |uid| [ uid, (payments[uid] || zero) - (shares[uid] || zero) ] }
  end

  def user_shares
    return {} unless @order.splits_configured?

    shares = Hash.new(BigDecimal('0'))

    @order.order_items.includes(:order_item_splits).each do |item|
      item_cost = item.price * item.quantity
      splits = item.order_item_splits

      case @order.sharing_type
      when 'share'
        total_shares = splits.sum(&:share)
        next if total_shares.zero?
        splits.each { |s| shares[s.user_id] += item_cost * s.share / total_shares }
      when 'percent'
        splits.each { |s| shares[s.user_id] += item_cost * s.share / 100 }
      when 'amount'
        splits.each { |s| shares[s.user_id] += s.share }
      end
    end

    shares
  end

  def user_payments
    payments = Hash.new(BigDecimal('0'))
    @order.order_payment_transactions.confirmed.each do |pt|
      payments[pt.user_id] += pt.amount
    end
    payments
  end
end
