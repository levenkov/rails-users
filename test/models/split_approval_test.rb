require 'test_helper'

class SplitApprovalTest < ActiveSupport::TestCase
  test 'valid approval' do
    approval = SplitApproval.new(
      order: orders(:submitted_order),
      user: users(:regular),
      approved_at: Time.current
    )
    assert approval.valid?
  end

  test 'requires approved_at' do
    approval = SplitApproval.new(
      order: orders(:submitted_order),
      user: users(:regular)
    )
    assert_not approval.valid?
    assert_includes approval.errors[:approved_at], "can't be blank"
  end

  test 'enforces uniqueness of user per order' do
    SplitApproval.create!(
      order: orders(:submitted_order),
      user: users(:regular),
      approved_at: Time.current
    )

    duplicate = SplitApproval.new(
      order: orders(:submitted_order),
      user: users(:regular),
      approved_at: Time.current
    )
    assert_not duplicate.valid?
  end

  test 'belongs to order' do
    approval = SplitApproval.new(
      order: orders(:submitted_order),
      user: users(:regular),
      approved_at: Time.current
    )
    assert_equal orders(:submitted_order), approval.order
  end

  test 'belongs to user' do
    approval = SplitApproval.new(
      order: orders(:submitted_order),
      user: users(:regular),
      approved_at: Time.current
    )
    assert_equal users(:regular), approval.user
  end
end
