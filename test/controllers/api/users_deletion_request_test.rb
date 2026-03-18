require 'test_helper'

class Api::UsersDeletionRequestSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'POST /users/deletion_request should disable user account' do
    user = User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    sign_in user

    assert_equal false, user.disabled

    post '/users/deletion_request', as: :json

    assert_response :no_content

    user.reload
    assert_equal true, user.disabled
  end

  test 'POST /users/deletion_request requires authentication' do
    post '/users/deletion_request', as: :json

    assert_response :unauthorized
  end
end
