require 'test_helper'

class CartItemTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular)
    @market_one = markets(:one)
    @market_two = markets(:two)
    @laptop_variant = article_variants(:laptop_default)
    @bread_variant = article_variants(:bread_default)
  end

  test 'valid when variant belongs to cart market' do
    cart = Cart.create!(owner: @user, market: @market_one)
    item = cart.cart_items.build(article_variant: @laptop_variant, user: @user, quantity: 1)
    assert item.valid?
  end

  test 'invalid when variant belongs to different market' do
    cart = Cart.create!(owner: @user, market: @market_one)
    item = cart.cart_items.build(article_variant: @bread_variant, user: @user, quantity: 1)
    assert_not item.valid?
    assert_includes item.errors[:article_variant], 'must belong to the same market as the cart'
  end
end
