require 'test_helper'

class OrderItemSplitTest < ActiveSupport::TestCase
  test 'valid split' do
    split = order_item_splits(:laptop_regular_split)
    assert split.valid?
  end

  test 'requires share greater than 0' do
    split = OrderItemSplit.new(order_item: order_items(:laptop_item), user: users(:regular), share: 0)
    assert_not split.valid?
    assert_includes split.errors[:share], 'must be greater than 0'
  end

  test 'requires share' do
    split = OrderItemSplit.new(order_item: order_items(:laptop_item), user: users(:regular))
    assert_not split.valid?
    assert_includes split.errors[:share], "can't be blank"
  end

  test 'belongs to order item' do
    split = order_item_splits(:laptop_regular_split)
    assert_equal order_items(:laptop_item), split.order_item
  end

  test 'belongs to user' do
    split = order_item_splits(:laptop_regular_split)
    assert_equal users(:regular), split.user
  end
end
