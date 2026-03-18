require 'test_helper'

class SplittingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @order = orders(:submitted_order)
    sign_in @user
  end

  test 'show returns success for member' do
    get order_splitting_path(@order)
    assert_response :success
  end

  test 'show requires authentication' do
    sign_out @user
    get order_splitting_path(@order)
    assert_redirected_to new_user_session_path
  end

  test 'show returns forbidden for non-member' do
    other_order = orders(:delivery_waiting_order)
    get order_splitting_path(other_order)
    assert_redirected_to root_path
  end
end
