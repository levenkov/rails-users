require 'test_helper'
require_relative 'concerns/smoke_test_helpers'

class UsersSmokeTest < ActionDispatch::IntegrationTest
  include SmokeTestHelpers
  def setup
    @user = User.create!(
      name: 'Test User',
      email: "user_#{SecureRandom.hex(4)}@example.com",
      password: 'password123',
      role: 'regular'
    )
  end

  test 'root page redirects unauthenticated user to login' do
    get root_path
    assert_redirected_to new_user_session_path
  end

  test 'root page loads for authenticated user' do
    sign_in @user
    get root_path
    assert_html_success
  end

  test 'user registration page loads without errors' do
    get new_user_registration_path
    assert_html_success
  end

  test 'user login page loads without errors' do
    get new_user_session_path
    assert_html_success
  end

  test 'user profile page loads for authenticated user' do
    sign_in @user
    get users_me_path
    assert_html_success
  end

  test 'user profile page redirects unauthenticated user in HTML' do
    get users_me_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test 'user profile page returns unauthorized for unauthenticated user in JSON' do
    get users_me_path, headers: { 'Accept' => 'application/json' }
    assert_response :unauthorized
  end
end
