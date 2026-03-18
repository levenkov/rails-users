require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  test 'valid order' do
    order = orders(:submitted_order)
    assert order.valid?
  end

  test 'has and belongs to many users' do
    order = orders(:submitted_order)
    assert_includes order.users, users(:regular)
  end

  test 'has order item splits through order items' do
    order = orders(:submitted_order)
    assert_includes order.order_item_splits, order_item_splits(:laptop_regular_split)
  end

  test 'default sharing type is nil' do
    order = Order.new
    assert_nil order.sharing_type
  end

  test 'validates sharing type inclusion' do
    order = orders(:submitted_order)
    order.sharing_type = 'invalid'
    assert_not order.valid?
  end

  test 'allows nil sharing type' do
    order = orders(:submitted_order)
    order.sharing_type = nil
    assert order.valid?
  end

  test 'initial state is submitted' do
    order = Order.new
    assert_equal 'submitted', order.state
  end

  test 'cannot wait_for_delivery without all participant approvals' do
    order = orders(:submitted_order)
    assert_not order.may_wait_for_delivery?
  end

  test 'can wait_for_delivery when all participants approved and splits configured' do
    order = orders(:submitted_order)
    order.update!(sharing_type: 'share')

    order.users.each do |user|
      order.split_approvals.create!(user: user, approved_at: Time.current)
    end

    assert order.may_start_preparing?
    order.start_preparing!
    assert_equal 'preparing', order.state

    assert order.may_wait_for_delivery?
    order.wait_for_delivery!
    assert_equal 'delivery_waiting', order.state
  end

  test 'all_participants_approved? checks sharing_type and approvals' do
    order = orders(:submitted_order)
    assert_not order.all_participants_approved?

    order.update!(sharing_type: 'share')
    assert_not order.all_participants_approved?

    order.users.each do |user|
      order.split_approvals.create!(user: user, approved_at: Time.current)
    end
    assert order.all_participants_approved?
  end

  test 'reset_approvals! clears all approvals' do
    order = orders(:submitted_order)
    order.split_approvals.create!(user: users(:regular), approved_at: Time.current)
    assert_equal 1, order.split_approvals.count

    order.reset_approvals!
    assert_equal 0, order.split_approvals.count
  end

  test 'cannot skip states' do
    order = orders(:submitted_order)
    assert_not order.may_start_delivery?
    assert_not order.may_finish?
  end

  test 'full state transition chain' do
    order = orders(:submitted_order)
    order.update!(sharing_type: 'share')
    order.users.each do |user|
      order.split_approvals.create!(user: user, approved_at: Time.current)
    end

    order.start_preparing!
    order.wait_for_delivery!
    order.start_delivery!
    order.finish!
    assert_equal 'finished', order.state
  end
end
