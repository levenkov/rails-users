require 'test_helper'

class OrderItemTest < ActiveSupport::TestCase
  test 'valid order item' do
    item = order_items(:laptop_item)
    assert item.valid?
  end

  test 'requires quantity greater than 0' do
    item = OrderItem.new(order: orders(:submitted_order), article: articles(:laptop),
      article_variant: article_variants(:laptop_default), price: 10, quantity: 0)
    assert_not item.valid?
    assert_includes item.errors[:quantity], 'must be greater than 0'
  end

  test 'requires price' do
    item = OrderItem.new(order: orders(:submitted_order), article: articles(:laptop),
      article_variant: article_variants(:laptop_default), quantity: 1)
    assert_not item.valid?
    assert_includes item.errors[:price], "can't be blank"
  end

  test 'has many order item splits' do
    item = order_items(:laptop_item)
    assert_includes item.order_item_splits, order_item_splits(:laptop_regular_split)
    assert_includes item.order_item_splits, order_item_splits(:laptop_admin_split)
  end
end
