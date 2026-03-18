require 'test_helper'

class Api::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    sign_in @user
  end

  test 'search requires authentication' do
    sign_out @user
    get search_api_users_path(q: 'test'), as: :json
    assert_response :unauthorized
  end

  test 'search returns empty array for blank query' do
    get search_api_users_path(q: ''), as: :json
    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test 'search returns matching users by name' do
    get search_api_users_path(q: @user.name[0..3]), as: :json
    assert_response :success

    results = JSON.parse(response.body)
    assert results.any? { |u| u['id'] == @user.id }
    results.each do |u|
      assert u.key?('id')
      assert u.key?('name')
      assert u.key?('email')
    end
  end

  test 'search returns matching users by email' do
    get search_api_users_path(q: @user.email.split('@').first), as: :json
    assert_response :success

    results = JSON.parse(response.body)
    assert results.any? { |u| u['id'] == @user.id }
  end

  test 'search returns empty array when no match' do
    get search_api_users_path(q: 'zzzznonexistentzzzz'), as: :json
    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test 'search excludes disabled users' do
    disabled_user = User.create!(name: 'Disabled', email: 'disabled@test.com', password: 'password123', disabled: true)
    get search_api_users_path(q: 'Disabled'), as: :json
    assert_response :success

    results = JSON.parse(response.body)
    assert_not results.any? { |u| u['id'] == disabled_user.id }
  end

  test 'search limits results to 10' do
    get search_api_users_path(q: 'a'), as: :json
    assert_response :success

    results = JSON.parse(response.body)
    assert results.length <= 10
  end
end
