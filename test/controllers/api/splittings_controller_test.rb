require 'test_helper'

class Api::SplittingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @admin = users(:admin)
    @order = orders(:submitted_order)
    @laptop_item = order_items(:laptop_item)
    @phone_item = order_items(:phone_item)
    sign_in @user
  end

  # -- show --

  test 'show returns full order data' do
    get api_order_splitting_path(@order), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @order.id, json['id']
    assert json.key?('order_items')
    assert json.key?('users')
    assert json.key?('split_approvals')
    assert json.key?('sharing_type')
  end

  test 'show requires authentication' do
    sign_out @user
    get api_order_splitting_path(@order), as: :json
    assert_response :unauthorized
  end

  test 'show returns forbidden for non-member' do
    other_order = orders(:delivery_waiting_order)
    get api_order_splitting_path(other_order), as: :json
    assert_response :forbidden
  end

  # -- update --

  test 'update sets sharing_type and splits' do
    put api_order_splitting_path(@order), params: {
      sharing_type: 'share',
      splits: {
        @laptop_item.id => [
          { user_id: @user.id, share: 3 }
        ]
      }
    }, as: :json
    assert_response :success

    @order.reload
    assert_equal 'share', @order.sharing_type
    assert_equal 1, @laptop_item.order_item_splits.count
  end

  test 'update resets approvals' do
    @order.split_approvals.create!(user: @user, approved_at: Time.current)
    assert_equal 1, @order.split_approvals.count

    put api_order_splitting_path(@order), params: {
      sharing_type: 'percent',
      splits: {
        @laptop_item.id => [
          { user_id: @user.id, share: 100 }
        ]
      }
    }, as: :json
    assert_response :success

    assert_equal 0, @order.split_approvals.reload.count
  end

  test 'update requires authentication' do
    sign_out @user
    put api_order_splitting_path(@order), params: { sharing_type: 'share' }, as: :json
    assert_response :unauthorized
  end

  test 'update allowed for non-submitted order' do
    sign_in @admin
    non_submitted_order = orders(:delivery_waiting_order)
    put api_order_splitting_path(non_submitted_order), params: { sharing_type: 'share' }, as: :json
    assert_response :success
  end
end
