require 'test_helper'

class LoginErrorHandlingTest < ActionDispatch::IntegrationTest
  test 'should return proper JSON error for invalid login credentials' do
    user = User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'correct_password',
      password_confirmation: 'correct_password'
    )

    post '/users/sign_in',
      params: {
        user: {
          email: 'test@example.com',
          password: 'wrong_password'
        }
      }.to_json,
      headers: {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }

    assert_response :unauthorized

    json_response = JSON.parse(response.body)

    assert_equal 'error', json_response['result']
    assert_not_nil json_response['message']

    assert_match /Invalid.*password/, json_response['message']
    assert_no_match /unknown error/i, json_response['message']

    assert json_response.key?('result'), 'Response must include result field'
    assert json_response.key?('message'), 'Response must include message field'
    assert_not_equal '', json_response['message'], 'Message should not be empty'
  end

  test 'should return proper JSON error for non-existent user' do
    post '/users/sign_in',
      params: {
        user: {
          email: 'nonexistent@example.com',
          password: 'any_password'
        }
      }.to_json,
      headers: {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }

    assert_response :unauthorized

    json_response = JSON.parse(response.body)

    assert_equal 'error', json_response['result']
    assert_not_nil json_response['message']

    assert_match /Invalid.*password/, json_response['message']
    assert_no_match /unknown error/i, json_response['message']

    assert json_response.key?('result'), 'Response must include result field'
    assert json_response.key?('message'), 'Response must include message field'
    assert_not_equal '', json_response['message'], 'Message should not be empty'
  end

  test 'should handle empty login data gracefully' do
    post '/users/sign_in',
      params: {}.to_json,
      headers: {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }

    assert_response :unauthorized

    json_response = JSON.parse(response.body)
    assert_equal 'error', json_response['result']
    assert_not_nil json_response['message']

    assert json_response.key?('result'), 'Response must include result field'
    assert json_response.key?('message'), 'Response must include message field'
    assert_not_equal '', json_response['message'], 'Message should not be empty'
  end

  test 'should prevent disabled user from logging in' do
    user = User.create!(
      name: 'Disabled User',
      email: 'disabled@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      disabled: true
    )

    post '/users/sign_in',
      params: {
        user: {
          email: 'disabled@example.com',
          password: 'password123'
        }
      }.to_json,
      headers: {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }

    assert_response :unauthorized

    json_response = JSON.parse(response.body)

    assert_equal 'error', json_response['result']
    assert_not_nil json_response['message']
    assert_match /disabled/i, json_response['message']

    assert json_response.key?('result'), 'Response must include result field'
    assert json_response.key?('message'), 'Response must include message field'
  end
end
