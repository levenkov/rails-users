require 'test_helper'
require_relative 'concerns/smoke_test_helpers'

class AdminUsersSmokeTest < ActionDispatch::IntegrationTest
  include SmokeTestHelpers

  def setup
    @admin_user = users(:admin)
    @regular_user = users(:regular)
  end

  test 'admin users index loads without errors' do
    sign_in @admin_user
    get admin_users_path
    assert_html_success
  end

  test 'admin users index with search loads without errors' do
    sign_in @admin_user
    get admin_users_path, params: { search: 'test' }
    assert_html_success
  end

  test 'admin users index with pagination loads without errors' do
    sign_in @admin_user
    get admin_users_path, params: { page: 1 }
    assert_html_success
  end

  test 'admin user edit page loads without errors' do
    sign_in @admin_user
    get edit_admin_user_path(@regular_user)
    assert_html_success
  end

  test 'admin users redirects unauthenticated user' do
    get admin_users_path
    assert_response :redirect
  end

  test 'admin users blocks regular user' do
    sign_in @regular_user
    get admin_users_path
    assert_html_forbidden
  end

  test 'admin user edit blocks regular user' do
    sign_in @regular_user
    get edit_admin_user_path(@admin_user)
    assert_html_forbidden
  end
end
