require 'test_helper'

class SnapshotRecalculationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular)
    @admin = users(:admin)
    @order = orders(:finished_order)

    @item = @order.order_items.create!(
      article: articles(:laptop),
      article_variant: article_variants(:laptop_default),
      quantity: 1,
      price: 1000.00
    )
    @order.update!(sharing_type: 'share')
    @item.order_item_splits.create!(user: @user, share: 1)
    @item.order_item_splits.create!(user: @admin, share: 1)
    @order.order_payment_transactions.create!(user: @user, amount: 1000.00, confirmed_at: Time.current)
  end

  test 'recalculates snapshots after p2p payment change' do
    # First archive the order
    result = OrderArchiveService.new(@order, @user).call
    assert result.success?
    assert @order.reload.archived?

    original_balance = @order.user_pair_balances.first.balance

    # Now recalculate (simulating a p2p payment change)
    SnapshotRecalculationService.new(@user.id, @admin.id).call

    # Order should be re-archived with recalculated balance
    @order.reload
    assert @order.archived?
    assert_equal 1, @order.user_pair_balances.count
  end

  test 'does nothing when no snapshots exist' do
    assert_nothing_raised do
      SnapshotRecalculationService.new(@user.id, @admin.id).call
    end
  end
end
