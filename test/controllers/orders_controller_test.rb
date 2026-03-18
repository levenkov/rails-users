require 'test_helper'

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @admin = users(:admin)
    @order = orders(:submitted_order)
    @article = articles(:laptop)
    @phone = articles(:phone)
    @variant = article_variants(:laptop_default)
    @phone_variant = article_variants(:phone_default)
    sign_in @user
  end

  # -- index --

  test 'index returns success' do
    get orders_path
    assert_response :success
  end

  test 'index requires authentication' do
    sign_out @user
    get orders_path
    assert_redirected_to new_user_session_path
  end

  # -- show --

  test 'show returns success for member' do
    get order_path(@order)
    assert_response :success
  end

  test 'show requires authentication' do
    sign_out @user
    get order_path(@order)
    assert_redirected_to new_user_session_path
  end

  # -- new redirects to carts --

  test 'new redirects to carts' do
    get new_order_path
    assert_redirected_to carts_path
  end

  test 'new requires authentication' do
    sign_out @user
    get new_order_path
    assert_redirected_to new_user_session_path
  end

  # -- checkout --

  test 'checkout with cart items returns success' do
    add_to_cart(@variant.id)
    cart = @user.my_carts.first
    get checkout_orders_path(cart_id: cart.id)
    assert_response :success
  end

  test 'checkout with empty cart redirects' do
    get checkout_orders_path
    assert_redirected_to carts_path
  end

  test 'checkout by non-owner redirects to cart' do
    sign_out @user
    sign_in @admin
    add_to_cart(@variant.id)
    admin_cart = @admin.reload.my_carts.first
    admin_cart.users << @user

    sign_out @admin
    sign_in @user
    get checkout_orders_path(cart_id: admin_cart.id)

    assert_redirected_to cart_path(admin_cart)
  end

  test 'checkout requires authentication' do
    sign_out @user
    get checkout_orders_path
    assert_redirected_to new_user_session_path
  end

  # -- create with participants --

  test 'creates order with selected participants' do
    add_to_cart(@variant.id)
    cart = @user.my_carts.first

    assert_difference('Order.count') do
      post orders_path, params: { cart_id: cart.id, order: {
        participant_ids: [ @user.id, @admin.id ]
      } }
    end

    order = Order.last
    assert_redirected_to order_path(order)
    assert_nil order.sharing_type
    assert_equal 1, order.order_items.count
    assert_includes order.users, @user
    assert_includes order.users, @admin
  end

  test 'current user always included in participants' do
    add_to_cart(@variant.id)
    cart = @user.my_carts.first

    post orders_path, params: { cart_id: cart.id, order: { participant_ids: [ @admin.id ] } }

    order = Order.last
    assert_includes order.users, @user
    assert_includes order.users, @admin
  end

  test 'create order without explicit participants includes current user' do
    add_to_cart(@variant.id)
    cart = @user.my_carts.first

    assert_difference('Order.count') do
      post orders_path, params: { cart_id: cart.id, order: {} }
    end

    order = Order.last
    assert_includes order.users, @user
  end

  # -- create with multiple items --

  test 'create order with multiple cart items' do
    add_to_cart(@variant.id)
    add_to_cart(@phone_variant.id)
    cart = @user.my_carts.first

    assert_difference('Order.count') do
      assert_difference('OrderItem.count', 2) do
        post orders_path, params: { cart_id: cart.id, order: {
          participant_ids: [ @user.id ]
        } }
      end
    end

    assert_equal 2, Order.last.order_items.count
  end

  # -- prices come from variant, not user input --

  test 'prices come from article variant' do
    add_to_cart(@variant.id)
    cart = @user.my_carts.first
    post orders_path, params: { cart_id: cart.id, order: {} }

    order = Order.last
    assert_equal @variant.price, order.order_items.first.price
  end

  # -- cart closed after successful order --

  test 'cart closed after successful order creation' do
    add_to_cart(@variant.id)
    cart = @user.my_carts.first
    post orders_path, params: { cart_id: cart.id, order: {} }

    assert cart.reload.closed?
  end

  test 'order stores reference to source cart' do
    add_to_cart(@variant.id)
    cart = @user.my_carts.first
    post orders_path, params: { cart_id: cart.id, order: {} }

    assert_equal cart, Order.last.cart
  end

  test 'order items have added_by_user_id from cart' do
    add_to_cart(@variant.id)
    cart = @user.my_carts.first
    post orders_path, params: { cart_id: cart.id, order: {} }

    assert_equal @user.id, Order.last.order_items.first.added_by_user_id
  end

  # -- cart participants carried to order --

  test 'cart participants included in order' do
    add_to_cart(@variant.id)
    cart = @user.my_carts.first
    cart.users << @admin

    post orders_path, params: { cart_id: cart.id, order: {} }

    order = Order.last
    assert_includes order.users, @user
    assert_includes order.users, @admin
  end

  # -- empty cart redirects --

  test 'create with empty cart redirects to carts' do
    post orders_path, params: { order: {} }
    assert_redirected_to carts_path
  end

  # -- authentication required --

  test 'create by non-owner does not create order' do
    sign_out @user
    sign_in @admin
    add_to_cart(@variant.id)
    admin_cart = @admin.reload.my_carts.first
    admin_cart.users << @user

    sign_out @admin
    sign_in @user

    assert_no_difference('Order.count') do
      post orders_path, params: { cart_id: admin_cart.id, order: {} }
    end
    assert_redirected_to cart_path(admin_cart)
  end

  test 'create requires authentication' do
    sign_out @user
    post orders_path, params: { order: {} }
    assert_redirected_to new_user_session_path
  end

  test 'create sets owner to current user' do
    add_to_cart(@variant.id)
    cart = @user.my_carts.first
    post orders_path, params: { cart_id: cart.id, order: {} }
    assert_equal @user, Order.last.owner
  end

  # -- archive --

  test 'archive a finished order' do
    finished = orders(:finished_order)
    item = finished.order_items.create!(
      article: @article, article_variant: @variant, quantity: 1, price: 100.00
    )
    finished.update!(sharing_type: 'share')
    item.order_item_splits.create!(user: @user, share: 1)
    item.order_item_splits.create!(user: @admin, share: 1)

    post archive_order_path(finished)
    assert_redirected_to order_path(finished)
    assert finished.reload.archived?
  end

  test 'archive requires owner' do
    finished = orders(:finished_order)
    sign_out @user
    sign_in @admin
    post archive_order_path(finished)
    # Policy redirects to root with alert for non-owner
    assert_redirected_to root_path
  end

  test 'archive requires authentication' do
    sign_out @user
    post archive_order_path(orders(:finished_order))
    assert_redirected_to new_user_session_path
  end

  private

  def add_to_cart(variant_id)
    post add_carts_path(article_variant_id: variant_id)
  end
end
