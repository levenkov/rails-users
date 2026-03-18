require 'test_helper'

class Users::PasswordsControllerTest < ActionDispatch::IntegrationTest
  test 'password reset with invalid email format returns errors in standard format' do
    post '/users/password', params: {
      user: {
        email: 'invalid-email'
      }
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)

    assert json_response['errors'].present?, 'Response should contain errors hash'
    assert json_response['errors']['email'].present?, 'Errors should include email field'
  end

  test 'password reset with blank email returns errors in standard format' do
    post '/users/password', params: {
      user: {
        email: ''
      }
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)

    assert json_response['errors'].present?, 'Response should contain errors hash'
    assert json_response['errors']['email'].present?, 'Errors should include email field'
  end

  test 'password reset with valid email returns success' do
    user = users(:regular)

    post '/users/password', params: {
      user: {
        email: user.email
      }
    }, as: :json

    assert_response :success
  end

  test 'password reset with non-existent email returns error' do
    post '/users/password', params: {
      user: {
        email: 'nonexistent@example.com'
      }
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)

    assert json_response['errors'].present?, 'Response should contain errors hash'
    assert json_response['errors']['email'].present?, 'Errors should include email field'
  end
end
