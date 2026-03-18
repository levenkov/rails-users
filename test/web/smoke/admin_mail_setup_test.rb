require 'test_helper'
require_relative 'concerns/smoke_test_helpers'

class AdminMailSetupSmokeTest < ActionDispatch::IntegrationTest
  include SmokeTestHelpers

  def setup
    @admin_user = User.create!(
      name: 'Admin User',
      email: "admin_#{SecureRandom.hex(4)}@example.com",
      password: 'password123',
      role: 'admin'
    )

    @regular_user = User.create!(
      name: 'Regular User',
      email: "user_#{SecureRandom.hex(4)}@example.com",
      password: 'password123',
      role: 'regular'
    )
  end

  test 'admin mail setup index loads for admin users' do
    sign_in @admin_user
    get admin_mail_setup_index_path
    assert_html_success
  end

  test 'admin mail setup index redirects regular users' do
    sign_in @regular_user
    get admin_mail_setup_index_path
    assert_html_forbidden
  end

  test 'admin mail setup index redirects unauthenticated users' do
    get admin_mail_setup_index_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test 'admin mail setup authorize_google redirects to Google OAuth for admin users' do
    sign_in @admin_user
    get authorize_google_admin_mail_setup_index_path
    assert_response :redirect
    assert_match /accounts\.google\.com/, response.location
  end

  test 'admin mail setup callback loads for admin users' do
    sign_in @admin_user
    get callback_admin_mail_setup_index_path
    assert_html_success
  end
end
