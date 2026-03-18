require 'test_helper'

class Api::Splitting::ParticipantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @admin = users(:admin)
    @order = orders(:submitted_order)
    @laptop_item = order_items(:laptop_item)
    sign_in @user
  end

  # -- create --

  test 'add participant' do
    assert_not @order.users.exists?(@admin.id)

    post api_order_splitting_participants_path(@order),
      params: { user_id: @admin.id }, as: :json
    assert_response :success

    assert @order.users.exists?(@admin.id)
  end

  test 'adding participant resets approvals' do
    @order.split_approvals.create!(user: @user, approved_at: Time.current)

    post api_order_splitting_participants_path(@order),
      params: { user_id: @admin.id }, as: :json
    assert_response :success

    assert_equal 0, @order.split_approvals.count
  end

  test 'adding existing participant is idempotent' do
    initial_count = @order.users.count

    post api_order_splitting_participants_path(@order),
      params: { user_id: @user.id }, as: :json
    assert_response :success

    assert_equal initial_count, @order.users.count
  end

  test 'requires authentication' do
    sign_out @user
    post api_order_splitting_participants_path(@order),
      params: { user_id: @admin.id }, as: :json
    assert_response :unauthorized
  end

  # -- destroy --

  test 'remove participant' do
    @order.users << @admin

    delete api_order_splitting_participant_path(@order, @admin), as: :json
    assert_response :success

    assert_not @order.users.exists?(@admin.id)
  end

  test 'removing participant deletes their splits' do
    @order.users << @admin

    assert_difference('OrderItemSplit.count', -1) do
      delete api_order_splitting_participant_path(@order, @admin), as: :json
    end
  end

  test 'removing participant resets approvals' do
    @order.users << @admin
    @order.split_approvals.create!(user: @user, approved_at: Time.current)

    delete api_order_splitting_participant_path(@order, @admin), as: :json
    assert_response :success

    assert_equal 0, @order.split_approvals.count
  end

  test 'cannot remove last participant' do
    delete api_order_splitting_participant_path(@order, @user), as: :json
    assert_response :unprocessable_entity

    assert @order.users.exists?(@user.id)
  end
end
