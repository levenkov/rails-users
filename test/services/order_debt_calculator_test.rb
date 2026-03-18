require 'test_helper'

class OrderDebtCalculatorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular)
    @admin = users(:admin)
    @order = orders(:submitted_order)
    @order.users << @admin unless @order.users.include?(@admin)
    @laptop_item = order_items(:laptop_item)
    @phone_item = order_items(:phone_item)

    # Clear fixture splits to start clean
    OrderItemSplit.where(order_item: @order.order_items).delete_all
  end

  test 'returns empty when splits not configured' do
    assert_empty OrderDebtCalculator.new(@order).call
  end

  test 'returns empty when all balanced' do
    @order.update!(sharing_type: 'share')
    @laptop_item.order_item_splits.create!(user: @user, share: 1)

    item_cost = @laptop_item.price * @laptop_item.quantity
    @order.order_payment_transactions.create!(user: @user, amount: item_cost, confirmed_at: Time.current)

    assert_empty OrderDebtCalculator.new(@order.reload).call
  end

  test 'calculates debt with share type' do
    @order.update!(sharing_type: 'share')
    @laptop_item.order_item_splits.create!(user: @user, share: 2)
    @laptop_item.order_item_splits.create!(user: @admin, share: 1)

    item_cost = @laptop_item.price * @laptop_item.quantity
    @order.order_payment_transactions.create!(user: @user, amount: item_cost, confirmed_at: Time.current)

    debts = OrderDebtCalculator.new(@order.reload).call

    assert_equal 1, debts.length
    assert_equal @admin.id, debts[0][:from_user_id]
    assert_equal @user.id, debts[0][:to_user_id]
    assert_in_delta item_cost.to_f / 3, debts[0][:amount].to_f, 0.01
  end

  test 'calculates debt with percent type' do
    @order.update!(sharing_type: 'percent')
    @laptop_item.order_item_splits.create!(user: @user, share: 60)
    @laptop_item.order_item_splits.create!(user: @admin, share: 40)

    item_cost = @laptop_item.price * @laptop_item.quantity
    @order.order_payment_transactions.create!(user: @user, amount: item_cost, confirmed_at: Time.current)

    debts = OrderDebtCalculator.new(@order.reload).call

    assert_equal 1, debts.length
    assert_equal @admin.id, debts[0][:from_user_id]
    assert_in_delta item_cost.to_f * 0.4, debts[0][:amount].to_f, 0.01
  end

  test 'calculates debt with amount type' do
    @order.update!(sharing_type: 'amount')
    @laptop_item.order_item_splits.create!(user: @user, share: 600)
    @laptop_item.order_item_splits.create!(user: @admin, share: 399.99)

    @order.order_payment_transactions.create!(user: @user, amount: 999.99, confirmed_at: Time.current)

    debts = OrderDebtCalculator.new(@order.reload).call

    assert_equal 1, debts.length
    assert_equal @admin.id, debts[0][:from_user_id]
    assert_in_delta 399.99, debts[0][:amount].to_f, 0.01
  end

  test 'sums across multiple items' do
    @order.update!(sharing_type: 'share')
    @laptop_item.order_item_splits.create!(user: @user, share: 1)
    @phone_item.order_item_splits.create!(user: @admin, share: 1)

    total = @order.total
    @order.order_payment_transactions.create!(user: @user, amount: total, confirmed_at: Time.current)

    debts = OrderDebtCalculator.new(@order.reload).call

    assert_equal 1, debts.length
    assert_equal @admin.id, debts[0][:from_user_id]
    assert_in_delta (@phone_item.price * @phone_item.quantity).to_f, debts[0][:amount].to_f, 0.01
  end

  test 'ignores unconfirmed payments' do
    @order.update!(sharing_type: 'share')
    @laptop_item.order_item_splits.create!(user: @user, share: 1)
    @laptop_item.order_item_splits.create!(user: @admin, share: 1)

    item_cost = @laptop_item.price * @laptop_item.quantity
    @order.order_payment_transactions.create!(user: @user, amount: item_cost, confirmed_at: Time.current)
    @order.order_payment_transactions.create!(user: @admin, amount: item_cost / 2) # unconfirmed

    debts = OrderDebtCalculator.new(@order.reload).call

    assert_equal 1, debts.length
    assert_equal @admin.id, debts[0][:from_user_id]
  end
end
