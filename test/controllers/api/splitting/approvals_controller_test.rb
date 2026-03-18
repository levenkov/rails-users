require 'test_helper'

class Api::Splitting::ApprovalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @admin = users(:admin)
    @order = orders(:submitted_order)
    @laptop_item = order_items(:laptop_item)
    sign_in @user
  end

  # -- create --

  test 'create approval for current user' do
    configure_splits!

    assert_difference('SplitApproval.count') do
      post api_order_splitting_approval_path(@order), as: :json
    end
    assert_response :success

    assert @order.user_approved?(@user)
  end

  test 'create approval is idempotent' do
    configure_splits!
    @order.split_approvals.create!(user: @user, approved_at: Time.current)

    assert_no_difference('SplitApproval.count') do
      post api_order_splitting_approval_path(@order), as: :json
    end
    assert_response :success
  end

  test 'fails without splits configured' do
    post api_order_splitting_approval_path(@order), as: :json
    assert_response :unprocessable_entity
  end

  test 'requires authentication' do
    sign_out @user
    post api_order_splitting_approval_path(@order), as: :json
    assert_response :unauthorized
  end

  # -- destroy --

  test 'destroy revokes own approval' do
    configure_splits!
    @order.split_approvals.create!(user: @user, approved_at: Time.current)

    assert_difference('SplitApproval.count', -1) do
      delete api_order_splitting_approval_path(@order), as: :json
    end
    assert_response :success

    assert_not @order.user_approved?(@user)
  end

  private

  def configure_splits!
    @order.update!(sharing_type: 'share')
    @laptop_item.order_item_splits.find_or_create_by!(user: @user) do |s|
      s.share = 1
    end
  end
end
