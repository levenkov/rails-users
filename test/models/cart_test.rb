require 'test_helper'

class CartTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular)
    @market = markets(:one)
  end

  test 'requires market' do
    cart = Cart.new(owner: @user)
    assert_not cart.valid?
    assert_includes cart.errors[:market], 'must exist'
  end

  test 'valid with owner and market' do
    cart = Cart.new(owner: @user, market: @market)
    assert cart.valid?
  end
end
