require 'test_helper'

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @google_id_token_payload = {
      'iss' => 'https://accounts.google.com',
      'sub' => '123456789',
      'email' => 'test@example.com',
      'email_verified' => true,
      'name' => 'Test User',
      'iat' => Time.current.to_i,
      'exp' => (Time.current + 1.hour).to_i
    }

    @existing_user_payload = {
      'iss' => 'https://accounts.google.com',
      'sub' => 'existing_user_uid',
      'email' => 'vasilie.pupkine@gmail.com',
      'email_verified' => true,
      'name' => 'Vasilie Pupkine',
      'iat' => Time.current.to_i,
      'exp' => (Time.current + 1.hour).to_i
    }
  end

  test 'google_mobile login with existing user returns token' do
    Users::OmniauthCallbacksController.any_instance.stubs(:verify_google_id_token)
      .returns(@existing_user_payload)

    post '/users/auth/google_oauth2/mobile', params: {
      id_token: 'fake-token',
      action_type: 'login'
    }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['user'].present?
    assert_equal 'vasilie.pupkine@gmail.com', json_response['user']['email']
    assert json_response['token'].present?
  end

  test 'google_mobile login with non-existent user returns registration token' do
    Users::OmniauthCallbacksController.any_instance.stubs(:verify_google_id_token)
      .returns(@google_id_token_payload)

    post '/users/auth/google_oauth2/mobile', params: {
      id_token: 'fake-token',
      action_type: 'login'
    }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'no such user', json_response['result']
    assert json_response['registration_token'].present?
    assert json_response['user_data'].present?
    assert_equal 'test@example.com', json_response['user_data']['email']
    assert_equal 'Test User', json_response['user_data']['name']
  end

  test 'google_mobile registration creates new user when not exists' do
    Users::OmniauthCallbacksController.any_instance.stubs(:verify_google_id_token)
      .returns(@google_id_token_payload)

    assert_difference 'User.count', 1 do
      assert_difference 'UserOauth.count', 1 do
        post '/users/auth/google_oauth2/mobile', params: {
          id_token: 'fake-token',
          action_type: 'registration'
        }, as: :json
      end
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'logged in', json_response['result'], "Result should be 'logged in' for successful registration"
    assert json_response['user'].present?
    assert_equal 'test@example.com', json_response['user']['email']
    assert json_response['token'].present?, 'Token should be present in registration response'
  end

  test 'google_mobile registration with existing email returns error' do
    Users::OmniauthCallbacksController.any_instance.stubs(:verify_google_id_token)
      .returns(@existing_user_payload)

    post '/users/auth/google_oauth2/mobile', params: {
      id_token: 'fake-token',
      action_type: 'registration'
    }, as: :json

    assert_response :conflict
    json_response = JSON.parse(response.body)
    assert json_response['error'].present?
    assert json_response['error'].include?('already exists')
  end

  test 'google_mobile with missing id_token returns error' do
    post '/users/auth/google_oauth2/mobile', params: {
      action_type: 'login'
    }, as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert json_response['error'].present?
    assert json_response['error'].include?('Missing Google ID token')
  end

  test 'google_mobile with invalid id_token returns error' do
    Users::OmniauthCallbacksController.any_instance.stubs(:verify_google_id_token)
      .returns(nil)

    post '/users/auth/google_oauth2/mobile', params: {
      id_token: 'invalid-token',
      action_type: 'login'
    }, as: :json

    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert json_response['error'].present?
    assert json_response['error'].include?('Invalid Google ID token')
  end

  test 'google_mobile with invalid action_type returns error' do
    Users::OmniauthCallbacksController.any_instance.stubs(:verify_google_id_token)
      .returns(@google_id_token_payload)

    post '/users/auth/google_oauth2/mobile', params: {
      id_token: 'fake-token',
      action_type: 'invalid_action'
    }, as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert json_response['error'].present?
    assert json_response['error'].include?('Invalid action parameter')
  end

  test 'register_with_saved_token creates user successfully' do
    mock_redis = mock
    mock_redis.expects(:get).with('google_signin_no_user_test_token')
      .returns('fake-google-id-token')
    mock_redis.expects(:del).with('google_signin_no_user_test_token')

    Users::OmniauthCallbacksController.any_instance.stubs(:redis)
      .returns(mock_redis)

    Users::OmniauthCallbacksController.any_instance.stubs(:verify_google_id_token)
      .with('fake-google-id-token')
      .returns(@google_id_token_payload)

    assert_difference 'User.count', 1 do
      assert_difference 'UserOauth.count', 1 do
        post '/users/auth/google_oauth2/register_with_saved_token', params: {
          registration_token: 'test_token'
        }, as: :json
      end
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'logged in', json_response['result']
    assert json_response['user'].present?
    assert_equal 'test@example.com', json_response['user']['email']
    assert json_response['token'].present?, 'Token should be present in response'
  end

  test 'register_with_saved_token with invalid token returns error' do
    mock_redis = mock
    mock_redis.expects(:get).with('google_signin_no_user_invalid_token')
      .returns(nil)

    Users::OmniauthCallbacksController.any_instance.stubs(:redis)
      .returns(mock_redis)

    post '/users/auth/google_oauth2/register_with_saved_token', params: {
      registration_token: 'invalid_token'
    }, as: :json

    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert json_response['error'].present?
    assert json_response['error'].include?('Invalid or expired')
  end
end
