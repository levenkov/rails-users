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

  test 'index page redirects to login when not authenticated' do
    get root_path
    assert_response :redirect
  end

  test 'index page accessible when authenticated' do
    sign_in @regular_user
    get root_path
    assert_html_success
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
