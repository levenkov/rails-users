require 'application_system_test_case'

class CartTest < ApplicationSystemTestCase
  setup do
    @regular = users(:regular)
    @admin = users(:admin)
    @market = markets(:one)
    @variant = article_variants(:laptop_default)
    @phone_variant = article_variants(:phone_default)
  end

  test 'participant adds item after viewing shared cart via order something else' do
    # Admin has a cart with an item, regular user is a participant
    admin_cart = Cart.create!(owner: @admin, market: @market)
    admin_cart.users << @admin
    admin_cart.users << @regular
    admin_cart.cart_items.create!(article_variant: @variant, user: @admin, quantity: 1)

    sign_in_as(@regular)

    # Regular user views admin's shared cart
    visit cart_path(admin_cart)
    assert_selector 'table tbody tr', count: 1

    # Click "Order something else" → market page
    click_on 'Order something else'
    assert_current_path market_path(@market), ignore_query: true

    # Add an item
    first('button', text: 'Add to Cart').click

    # Item should be added to the shared cart, not a new personal cart
    assert_selector 'select option', text: /#{@admin.name}.*2 items/
  end

  test 'participant can toggle ready status' do
    admin_cart = Cart.create!(owner: @admin, market: @market)
    admin_cart.users << @admin
    admin_cart.users << @regular
    admin_cart.cart_items.create!(article_variant: @variant, user: @admin, quantity: 1)
    admin_cart.cart_items.create!(article_variant: @phone_variant, user: @regular, quantity: 1)

    sign_in_as(@regular)
    visit cart_path(admin_cart)

    # Button visible because regular user has items
    assert_selector 'button', text: "I'm ready"
    assert_no_selector 'span', text: 'Ready'

    # Mark as ready
    click_on "I'm ready"
    assert_text 'Cart', wait: 5

    # Badge appears and button changes
    assert_selector '.bg-green-100'
    assert_selector 'button', text: 'Undo ready'

    # Undo
    click_on 'Undo ready'
    assert_text 'Cart', wait: 5
    assert_no_selector '.bg-green-100'
    assert_selector 'button', text: "I'm ready"
  end

  test 'owner sees delete button and can destroy cart' do
    cart = Cart.create!(owner: @regular, market: @market)
    cart.users << @regular
    cart.cart_items.create!(article_variant: @variant, user: @regular, quantity: 1)

    sign_in_as(@regular)
    visit cart_path(cart)

    assert_selector 'a', text: 'Delete Cart'

    accept_confirm('Delete Cart?') do
      click_on 'Delete Cart'
    end

    assert_current_path carts_path
    assert_not Cart.exists?(cart.id)
  end

  test 'non-owner does not see delete button' do
    admin_cart = Cart.create!(owner: @admin, market: @market)
    admin_cart.users << @admin
    admin_cart.users << @regular
    admin_cart.cart_items.create!(article_variant: @variant, user: @admin, quantity: 1)

    sign_in_as(@regular)
    visit cart_path(admin_cart)

    assert_no_selector 'a', text: 'Delete Cart'
  end

  test 'ready button hidden when participant has no items' do
    admin_cart = Cart.create!(owner: @admin, market: @market)
    admin_cart.users << @admin
    admin_cart.users << @regular
    admin_cart.cart_items.create!(article_variant: @variant, user: @admin, quantity: 1)

    sign_in_as(@regular)
    visit cart_path(admin_cart)

    assert_no_selector 'button', text: "I'm ready"
  end

  private

  def sign_in_as(user)
    visit new_user_session_path
    fill_in 'user-email-field', with: user.email
    fill_in 'user-password-field', with: 'password123'
    find('#sign-in-button').click
    assert_text 'Puhatak', wait: 5
  end
end
