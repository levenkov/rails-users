class SnapshotRecalculationService
  def initialize(user_a_id, user_b_id)
    @low_id, @high_id = [ user_a_id, user_b_id ].sort
  end

  def call
    snapshots = UserPairBalance
      .where(user_low_id: @low_id, user_high_id: @high_id)
      .order(:order_id)

    return if snapshots.empty?

    order_ids = snapshots.pluck(:order_id)
    snapshots.delete_all

    Order.where(id: order_ids).update_all(archived_at: nil)

    orders = Order.where(id: order_ids).order(:id)
    orders.each do |order|
      result = OrderArchiveService.new(order, order.owner).call
      # If archiving fails (e.g., constraint not met), skip — the order stays unarchived
      next unless result.success?
    end
  end
end
