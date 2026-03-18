require 'test_helper'

class CartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @admin = users(:admin)
    @article = articles(:laptop)
    @phone = articles(:phone)
    @variant = article_variants(:laptop_default)
    @phone_variant = article_variants(:phone_default)
    sign_in @user
  end

  # -- add --

  test 'add article to cart' do
    assert_difference('CartItem.count') do
      post add_carts_path(article_variant_id: @variant.id)
    end
    cart = @user.reload.my_carts.first
    assert_redirected_to market_path(@article.market, cart_id: cart.id)
    item = cart.cart_items.find_by(article_variant: @variant, user: @user)
    assert_equal 1, item.quantity
    assert_equal @user, item.user
  end

  test 'add same article twice increments quantity' do
    post add_carts_path(article_variant_id: @variant.id)
    post add_carts_path(article_variant_id: @variant.id)

    assert_equal 2, @user.my_carts.first.cart_items.find_by(article_variant: @variant, user: @user).quantity
  end

  test 'add multiple different articles' do
    post add_carts_path(article_variant_id: @variant.id)
    post add_carts_path(article_variant_id: @phone_variant.id)

    assert_equal 2, @user.my_carts.first.cart_items.count
  end

  test 'add sets market on cart' do
    post add_carts_path(article_variant_id: @variant.id)
    assert_equal @article.market, @user.reload.my_carts.first.market
  end

  test 'add article from different market creates a new cart' do
    post add_carts_path(article_variant_id: @variant.id)
    bread_variant = article_variants(:bread_default)

    assert_difference('Cart.count') do
      post add_carts_path(article_variant_id: bread_variant.id)
    end

    assert_equal 2, @user.reload.my_carts.count
    assert_not_equal @user.my_carts.first.market, @user.my_carts.last.market
  end

  test 'add creates cart with owner as participant' do
    post add_carts_path(article_variant_id: @variant.id)

    cart = @user.reload.my_carts.first
    assert cart.users.exists?(@user.id)
  end

  test 'add requires authentication' do
    sign_out @user
    post add_carts_path(article_variant_id: @variant.id)
    assert_redirected_to new_user_session_path
  end

  # -- index --

  test 'index displays cart' do
    post add_carts_path(article_variant_id: @variant.id)
    get carts_path
    assert_response :success
  end

  test 'index with empty cart' do
    get carts_path
    assert_response :success
  end

  # -- show --

  test 'show displays shared cart' do
    # Admin creates a cart and adds regular user as participant
    sign_out @user
    sign_in @admin
    post add_carts_path(article_variant_id: @variant.id)
    admin_cart = @admin.reload.my_carts.first
    admin_cart.users << @user

    # Regular user can see admin's cart
    sign_out @admin
    sign_in @user
    get cart_path(admin_cart)
    assert_response :success
  end

  test 'show requires authentication' do
    sign_out @user
    get carts_path
    assert_redirected_to new_user_session_path
  end

  # -- update --

  test 'update changes quantities' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.my_carts.first
    item = cart.cart_items.find_by(article_variant: @variant, user: @user)
    patch cart_path(cart), params: { quantities: { item.id.to_s => 5 } }
    assert_redirected_to cart_path(cart)

    assert_equal 5, item.reload.quantity
  end

  test 'update with zero quantity removes item' do
    post add_carts_path(article_variant_id: @variant.id)
    post add_carts_path(article_variant_id: @phone_variant.id)
    cart = @user.my_carts.first
    item = cart.cart_items.find_by(article_variant: @variant, user: @user)
    patch cart_path(cart), params: { quantities: { item.id.to_s => 0 } }
    assert_redirected_to cart_path(cart)

    assert_nil cart.cart_items.find_by(article_variant: @variant, user: @user)
  end

  test 'update does not destroy cart when all items removed' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.my_carts.first
    item = cart.cart_items.find_by(article_variant: @variant, user: @user)
    patch cart_path(cart), params: { quantities: { item.id.to_s => 0 } }

    assert Cart.exists?(cart.id)
  end

  test 'update requires authentication' do
    sign_out @user
    post add_carts_path(article_variant_id: @variant.id)
    # Can't update without auth - just check redirect
    patch cart_path(id: 1), params: { quantities: {} }
    assert_redirected_to new_user_session_path
  end

  # -- destroy --

  test 'destroy by owner deletes cart' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.my_carts.first

    delete cart_path(cart)

    assert_not Cart.exists?(cart.id)
  end

  test 'destroy by non-owner does not delete cart' do
    sign_out @user
    sign_in @admin
    post add_carts_path(article_variant_id: @variant.id)
    admin_cart = @admin.reload.my_carts.first
    admin_cart.users << @user

    sign_out @admin
    sign_in @user
    delete cart_path(admin_cart)

    assert Cart.exists?(admin_cart.id), 'Cart should not be deleted by non-owner'
  end

  test 'destroy requires authentication' do
    sign_out @user
    delete cart_path(id: 1)
    assert_redirected_to new_user_session_path
  end

  # -- participant can update any items --

  test 'participant can update any items in shared cart' do
    # Admin creates a cart, adds user as participant
    sign_out @user
    sign_in @admin
    post add_carts_path(article_variant_id: @variant.id)
    admin_cart = @admin.reload.my_carts.first
    admin_cart.users << @user

    admin_item = admin_cart.cart_items.find_by(article_variant: @variant, user: @admin)

    # User can edit admin's items
    sign_out @admin
    sign_in @user
    patch cart_path(admin_cart), params: { quantities: { admin_item.id.to_s => 5 } }
    assert_equal 5, admin_item.reload.quantity
  end

  # -- market page with cart renders cart selector --

  test 'market show page renders cart selector when user has a cart' do
    post add_carts_path(article_variant_id: @variant.id)
    get market_path(@article.market)
    assert_response :success
  end

  # -- participants --

  test 'add participant' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.my_carts.first

    post add_participant_cart_path(cart), params: { user_id: @admin.id }, as: :json
    assert_response :success

    assert cart.users.exists?(@admin.id)
  end

  test 'remove participant' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.my_carts.first
    cart.users << @admin

    delete remove_participant_cart_path(cart, user_id: @admin.id), as: :json
    assert_response :no_content

    assert_not cart.users.exists?(@admin.id)
  end

  # -- closed cart protection --

  test 'add to closed cart creates a new cart instead' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.my_carts.first
    cart.close!

    assert_difference('Cart.count') do
      post add_carts_path(article_variant_id: @variant.id, cart_id: cart.id)
    end
    assert_equal 0, cart.reload.cart_items.count - 1, 'Closed cart should not receive new items'
  end

  test 'remove from closed cart does nothing' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.my_carts.first
    item_count = cart.cart_items.count
    cart.close!

    post remove_carts_path(article_variant_id: @variant.id, cart_id: cart.id)
    assert_equal item_count, cart.reload.cart_items.count
  end

  test 'update closed cart returns not found' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.my_carts.first
    item = cart.cart_items.first
    cart.close!

    patch cart_path(cart), params: { quantities: { item.id.to_s => 5 } }
    assert_response :not_found
  end

  test 'add participant to closed cart returns not found' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.my_carts.first
    cart.close!

    post add_participant_cart_path(cart), params: { user_id: @admin.id }, as: :json
    assert_response :not_found
  end

  test 'remove participant from closed cart returns not found' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.my_carts.first
    cart.users << @admin
    cart.close!

    delete remove_participant_cart_path(cart, user_id: @admin.id), as: :json
    assert_response :not_found
  end

  test 'toggle ready on closed cart returns not found' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.my_carts.first
    cart.close!

    post toggle_ready_cart_path(cart)
    assert_response :not_found
  end

  # -- toggle ready --

  test 'toggle ready marks participant as ready' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.my_carts.first

    post toggle_ready_cart_path(cart)
    assert_redirected_to cart_path(cart)
    assert cart.cart_participants.find_by(user: @user).ready?
  end

  test 'toggle ready again unmarks participant' do
    post add_carts_path(article_variant_id: @variant.id)
    cart = @user.my_carts.first

    post toggle_ready_cart_path(cart)
    post toggle_ready_cart_path(cart)
    assert_not cart.cart_participants.find_by(user: @user).ready?
  end
end
