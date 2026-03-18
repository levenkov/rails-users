require 'test_helper'
require_relative 'concerns/smoke_test_helpers'

class MainRoutesSmokeTest < ActionDispatch::IntegrationTest
  include SmokeTestHelpers

  def setup
    @regular_user = User.create!(
      name: 'Regular User',
      email: "regular_#{SecureRandom.hex(4)}@example.com",
      password: 'password123',
      role: 'regular'
    )
    @admin_user = User.create!(
      name: 'Admin User',
      email: "admin_#{SecureRandom.hex(4)}@example.com",
      password: 'password123',
      role: 'admin'
    )
  end

  # Index page

  test 'index redirects guest to login when users exist' do
    get root_path
    assert_redirected_to new_user_session_path
  end

  test 'index redirects guest to registration when no users exist' do
    UserPairBalance.delete_all
    OrderItemSplit.delete_all
    OrderItem.delete_all
    OrderPaymentTransaction.delete_all
    FinancialTransaction.delete_all
    Order.connection.execute('DELETE FROM orders_users')
    Order.delete_all
    CartItem.delete_all
    CartParticipant.delete_all
    Cart.delete_all
    ArticleVariant.delete_all
    Article.delete_all
    Market.delete_all
    UserOauth.delete_all
    User.delete_all
    get root_path
    assert_redirected_to new_user_registration_path
  end

  test 'index page shows markets for logged-in user' do
    sign_in @regular_user
    market = @regular_user.markets.create!(name: 'Test Market')
    get root_path
    assert_html_success
    assert_match market.name, response.body
  end

  test 'index page shows nav links for logged-in user' do
    sign_in @regular_user
    get root_path
    assert_html_success
    assert_select 'a[href=?]', users_me_path
    assert_select 'a[href=?]', destroy_user_session_path
  end

  test 'index page does not show admin link for regular user' do
    sign_in @regular_user
    get root_path
    assert_html_success
    assert_select 'a[href=?]', admin_users_path, count: 0
  end

  test 'index page shows admin link for admin user' do
    sign_in @admin_user
    get root_path
    assert_html_success
    assert_select 'a[href=?]', admin_users_path
  end

  test 'index page shows empty state when no markets' do
    OrderItemSplit.delete_all
    OrderItem.delete_all
    CartItem.delete_all
    CartParticipant.delete_all
    Cart.delete_all
    ArticleVariant.delete_all
    Article.delete_all
    Market.delete_all
    sign_in @regular_user
    get root_path
    assert_html_success
    assert_match(/no markets/i, response.body)
  end

  # Login

  test 'login page has email and password fields' do
    get new_user_session_path
    assert_html_success
    assert_select 'input#user-email-field'
    assert_select 'input#user-password-field'
  end

  test 'successful login redirects' do
    post user_session_path, params: {
      user: { email: @regular_user.email, password: 'password123' }
    }
    assert_response :redirect
  end

  test 'failed login shows error' do
    post user_session_path, params: {
      user: { email: @regular_user.email, password: 'wrongpassword' }
    }
    assert_response :redirect
    follow_redirect!
    assert_match(/invalid/i, response.body)
  end

  test 'logout redirects to root' do
    sign_in @regular_user
    delete destroy_user_session_path
    assert_response :redirect
  end

  # Registration

  test 'registration page has all fields' do
    get new_user_registration_path
    assert_html_success
    assert_select 'input#user_name'
    assert_select 'input#user_email'
    assert_select 'input#user_password'
    assert_select 'input#user_password_confirmation'
  end

  test 'successful registration creates user' do
    assert_difference('User.count', 1) do
      post user_registration_path, params: {
        user: {
          name: 'New User',
          email: "new_#{SecureRandom.hex(4)}@example.com",
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end
    assert_response :redirect
  end

  # Profile

  test 'profile shows user info' do
    sign_in @regular_user
    get users_me_path
    assert_html_success
    assert_match @regular_user.name, response.body
    assert_match @regular_user.email, response.body
  end

  test 'profile has change password link' do
    sign_in @regular_user
    get users_me_path
    assert_html_success
    assert_select 'a[href=?]', edit_user_registration_path
  end

  # Change password

  test 'change password form loads for authenticated user' do
    sign_in @regular_user
    get edit_user_registration_path
    assert_html_success
    assert_select 'input#user_password'
    assert_select 'input#user_password_confirmation'
  end

  # Admin

  test 'admin panel accessible to admin' do
    sign_in @admin_user
    get admin_users_path
    assert_html_success
  end

  test 'admin panel forbidden for regular user' do
    sign_in @regular_user
    get admin_users_path
    assert_html_forbidden
  end

  test 'admin panel redirects unauthenticated user' do
    get admin_users_path
    assert_response :redirect
  end
end
