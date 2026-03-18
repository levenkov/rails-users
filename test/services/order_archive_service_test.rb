require 'test_helper'

class OrderArchiveServiceTest < ActiveSupport::TestCase
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

  test 'archives a finished order and creates snapshots' do
    result = OrderArchiveService.new(@order, @user).call
    assert result.success?
    assert @order.reload.archived?
    assert_equal 1, @order.user_pair_balances.count
  end

  test 'fails if order is not finished' do
    order = orders(:submitted_order)
    result = OrderArchiveService.new(order, @user).call
    assert_not result.success?
    assert_equal 'Order must be finished before archiving.', result.error
  end

  test 'fails if user is not the owner' do
    result = OrderArchiveService.new(@order, @admin).call
    assert_not result.success?
    assert_equal 'Only the order owner can archive.', result.error
  end

  test 'fails if order is already archived' do
    @order.update!(archived_at: Time.current)
    result = OrderArchiveService.new(@order, @user).call
    assert_not result.success?
    assert_equal 'Order is already archived.', result.error
  end

  test 'fails if prior shared orders are not archived' do
    # Create an older unarchived order shared between the same users
    older_order = Order.create!(state: 'finished', sharing_type: 'share', owner: @user)
    older_order.users << @user
    older_order.users << @admin

    # Ensure older_order has a smaller id
    if older_order.id >= @order.id
      # This shouldn't happen with auto-increment but just in case
      skip 'Cannot guarantee ID ordering in test'
    end

    result = OrderArchiveService.new(@order, @user).call
    assert_not result.success?
    assert_equal 'All previous shared orders must be archived first.', result.error
  end
end
