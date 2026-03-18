require 'test_helper'

class UserPairBalanceTest < ActiveSupport::TestCase
  test 'valid user pair balance' do
    order = orders(:finished_order)
    upb = UserPairBalance.new(
      order: order,
      user_low: users(:admin),
      user_high: users(:regular),
      balance: 100.00
    )
    # Normalize IDs
    low_id, high_id = [ users(:admin).id, users(:regular).id ].sort
    upb.user_low_id = low_id
    upb.user_high_id = high_id
    assert upb.valid?
  end

  test 'requires balance' do
    upb = UserPairBalance.new(order: orders(:finished_order), user_low: users(:admin), user_high: users(:regular))
    assert_not upb.valid?
  end

  test 'for_pair normalizes user order' do
    order = orders(:finished_order)
    low_id, high_id = [ users(:admin).id, users(:regular).id ].sort
    UserPairBalance.create!(
      order: order,
      user_low_id: low_id,
      user_high_id: high_id,
      balance: 50.00
    )

    # Query in both orders should return same result
    result_a = UserPairBalance.for_pair(users(:admin), users(:regular))
    result_b = UserPairBalance.for_pair(users(:regular), users(:admin))
    assert_equal result_a.to_a, result_b.to_a
    assert_equal 1, result_a.count
  end
end
