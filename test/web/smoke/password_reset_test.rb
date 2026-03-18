require 'test_helper'
require_relative 'concerns/smoke_test_helpers'

class PasswordResetSmokeTest < ActionDispatch::IntegrationTest
  include SmokeTestHelpers

  def setup
    @user = User.create!(
      name: 'Test User',
      email: "user_#{SecureRandom.hex(4)}@example.com",
      password: 'password123',
      role: 'regular'
    )
  end

  test 'forgot password page loads' do
    get new_user_password_path
    assert_html_success
    assert_select 'h1', 'Forgot your password?'
    assert_select 'input#user-email-field'
    assert_select 'input#submit-button'
  end

  test 'forgot password page has styled layout' do
    get new_user_password_path
    assert_html_success
    assert_select 'div.min-h-screen'
  end

  test 'password reset request with valid email succeeds' do
    post user_password_path, params: {
      user: { email: @user.email }
    }

    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_match(/password/i, response.body)
  end

  test 'password reset request with invalid email shows error' do
    post user_password_path, params: {
      user: { email: 'nonexistent@example.com' }
    }

    assert_response :unprocessable_entity
    assert_select '#error_explanation'
  end

  test 'password reset edit page loads with valid token' do
    token = @user.send_reset_password_instructions

    get edit_user_password_path(reset_password_token: token)
    assert_html_success
    assert_select 'h1', 'Change your password'
    assert_select 'input#user-password-field'
    assert_select 'input#user-password-confirmation-field'
    assert_select 'input#submit-button'
  end

  test 'password reset edit page has styled layout' do
    token = @user.send_reset_password_instructions

    get edit_user_password_path(reset_password_token: token)
    assert_html_success
    assert_select 'div.min-h-screen'
  end

  test 'password can be changed with valid token' do
    token = @user.send_reset_password_instructions

    put user_password_path, params: {
      user: {
        reset_password_token: token,
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }
    }

    assert_response :redirect

    @user.reload
    assert @user.valid_password?('newpassword123')
  end

  test 'password change fails with mismatched confirmation' do
    token = @user.send_reset_password_instructions

    put user_password_path, params: {
      user: {
        reset_password_token: token,
        password: 'newpassword123',
        password_confirmation: 'differentpassword'
      }
    }

    assert_response :unprocessable_entity
    assert_select '#error_explanation'

    @user.reload
    assert @user.valid_password?('password123')
  end

  test 'password change fails with invalid token' do
    put user_password_path, params: {
      user: {
        reset_password_token: 'invalid-token',
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }
    }

    assert_response :unprocessable_entity
    assert_select '#error_explanation'
  end
end
