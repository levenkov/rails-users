require 'test_helper'

class Users::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test 'returns JSON when JSON format is requested' do
    user = users(:regular)
    sign_in user

    get '/users/me', as: :json

    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type

    json_response = JSON.parse(response.body)
    assert json_response['user'].present?
    assert_equal user.email, json_response['user']['email']
    assert_equal user.name, json_response['user']['name']
  end

  test 'requires authentication for JSON requests' do
    get '/users/me', as: :json

    assert_response :unauthorized
  end

  test 'returns HTML when HTML format is requested' do
    user = users(:regular)
    sign_in user

    get '/users/me'

    assert_response :success
    assert_match 'text/html', response.content_type
  end
end
