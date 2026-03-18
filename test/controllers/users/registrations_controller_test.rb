require 'test_helper'

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test 'successful registration returns JWT token' do
    assert_difference 'User.count', 1 do
      post '/users', params: {
        user: {
          name: 'Test User',
          email: 'newuser@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)

    # Check response structure
    assert_equal 'registered', json_response['result']
    assert json_response['user'].present?
    assert_equal 'newuser@example.com', json_response['user']['email']
    assert_equal 'Test User', json_response['user']['name']

    # Check that JWT token is in response body
    assert json_response['token'].present?, 'JWT token should be present in response body'

    # Also check Authorization header
    assert response.headers['Authorization'].present?, 'JWT token should also be in Authorization header'
    assert response.headers['Authorization'].starts_with?('Bearer '), "Authorization header should start with 'Bearer '"
  end

  test 'registration with invalid data returns errors' do
    assert_no_difference 'User.count' do
      post '/users', params: {
        user: {
          name: '',
          email: 'invalid',
          password: 'short',
          password_confirmation: 'different'
        }
      }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response['errors'].present?
  end

  test 'registration with existing email returns error' do
    existing_user = users(:regular)

    assert_no_difference 'User.count' do
      post '/users', params: {
        user: {
          name: 'Another User',
          email: existing_user.email,
          password: 'password123',
          password_confirmation: 'password123'
        }
      }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response['errors'].present?
    assert json_response['errors']['email'].present?
  end

  test 'successful password update returns success message' do
    user = users(:regular)
    sign_in user

    put '/users', params: {
      user: {
        current_password: 'password123',
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }
    }, as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)

    assert_equal 'updated', json_response['result']
    assert_equal 'Password updated successfully', json_response['message']
    assert json_response['user'].present?

    user.reload
    assert user.valid_password?('newpassword123')
  end

  test 'password update with incorrect current password fails' do
    user = users(:regular)
    sign_in user

    put '/users', params: {
      user: {
        current_password: 'wrongpassword',
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response['errors'].present?
    assert json_response['errors']['current_password'].present?

    user.reload
    assert user.valid_password?('password123')
  end

  test 'password update with mismatched confirmation fails' do
    user = users(:regular)
    sign_in user

    put '/users', params: {
      user: {
        current_password: 'password123',
        password: 'newpassword123',
        password_confirmation: 'differentpassword'
      }
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response['errors'].present?
    assert json_response['errors']['password_confirmation'].present?

    user.reload
    assert user.valid_password?('password123')
  end

  test 'password update without authentication fails' do
    put '/users', params: {
      user: {
        current_password: 'password123',
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }
    }, as: :json

    assert_response :unauthorized
  end

  test 'password update with too short password fails' do
    user = users(:regular)
    sign_in user

    put '/users', params: {
      user: {
        current_password: 'password123',
        password: 'short',
        password_confirmation: 'short'
      }
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response['errors'].present?
    assert json_response['errors']['password'].present?

    user.reload
    assert user.valid_password?('password123')
  end
end
