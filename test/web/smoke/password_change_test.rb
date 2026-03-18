require 'test_helper'
require_relative 'concerns/smoke_test_helpers'

class PasswordChangeSmokeTest < ActionDispatch::IntegrationTest
  include SmokeTestHelpers

  def setup
    @user = User.create!(
      name: 'Test User',
      email: "user_#{SecureRandom.hex(4)}@example.com",
      password: 'oldpassword123',
      role: 'regular'
    )
  end

  test 'password change page loads for authenticated user' do
    sign_in @user
    get edit_user_registration_path
    assert_html_success
    assert_select 'h1', 'Change Password'
  end

  test 'password change page redirects unauthenticated user' do
    get edit_user_registration_path
    assert_response :redirect
  end

  test 'successful password change updates password' do
    sign_in @user

    put user_registration_path, params: {
      user: {
        current_password: 'oldpassword123',
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }
    }

    assert_redirected_to users_me_path
    follow_redirect!
    assert_html_success
    assert_match(/updated/i, response.body)

    @user.reload
    assert @user.valid_password?('newpassword123')
  end

  test 'password change with incorrect current password fails' do
    sign_in @user

    put user_registration_path, params: {
      user: {
        current_password: 'wrongpassword',
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }
    }

    assert_response :unprocessable_entity
    assert_select '#error_explanation'

    @user.reload
    assert @user.valid_password?('oldpassword123')
  end
end
