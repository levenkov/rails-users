require 'test_helper'

class MarketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @market = markets(:one)
    @variant = article_variants(:laptop_default)
    sign_in @user
  end

  test 'show renders market page' do
    get market_path(@market)
    assert_response :success
  end

  test 'show does not include closed carts in market carts list' do
    # Create an open cart
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.reload.my_carts.first
    assert_not cart.closed

    # Close the cart
    cart.close!

    get market_path(@market)
    assert_response :success
    assert_select 'select option[value=?]', cart.id.to_s, count: 0,
      message: 'Closed cart should not appear in the cart selector'
  end

  test 'show only includes open carts in market carts list' do
    # Create two carts — one will be closed
    post add_carts_path(article_variant_id: @variant.id)
    closed_cart = @user.reload.my_carts.first
    closed_cart.close!

    post add_carts_path(article_variant_id: @variant.id)
    open_cart = @user.reload.my_carts.open.first

    get market_path(@market)
    assert_response :success
    assert_select 'select option[value=?]', open_cart.id.to_s, count: 1
    assert_select 'select option[value=?]', closed_cart.id.to_s, count: 0
  end

  test 'show does not select closed cart by default' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.reload.my_carts.first
    cart.close!

    get market_path(@market)
    assert_response :success
    # With no open carts, selected_cart_id should be nil — "New cart" should be selected
    assert_select 'select option[selected]' do |options|
      options.each do |opt|
        assert_not_equal cart.id.to_s, opt['value'],
          'Closed cart should not be the selected cart'
      end
    end
  end

  test 'show does not allow selecting closed cart via cart_id param' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.reload.my_carts.first
    cart.close!

    get market_path(@market, cart_id: cart.id)
    assert_response :success
    # The closed cart should not be selectable, so cart_quantities should be empty
    assert_select 'select option[value=?]', cart.id.to_s, count: 0
  end

  test 'show requires authentication' do
    sign_out @user
    get market_path(@market)
    assert_redirected_to new_user_session_path
  end
end
