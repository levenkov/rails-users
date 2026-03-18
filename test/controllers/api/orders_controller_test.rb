require 'test_helper'

class Api::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @admin = users(:admin)
    @order = orders(:submitted_order)
    @article = articles(:laptop)
    @variant = article_variants(:laptop_default)
    sign_in @user
  end

  # -- index --

  test 'index returns user orders' do
    get api_orders_path, as: :json
    assert_response :success
  end

  test 'index requires authentication' do
    sign_out @user
    get api_orders_path, as: :json
    assert_response :unauthorized
  end

  # -- show --

  test 'show returns an order with enriched data' do
    get api_order_path(@order), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @order.id, json['id']
    assert json.key?('order_items')
    assert json.key?('users')
    assert json.key?('split_approvals')
  end

  test 'show requires authentication' do
    sign_out @user
    get api_order_path(@order), as: :json
    assert_response :unauthorized
  end

  test 'show returns forbidden for non-member' do
    other_order = orders(:delivery_waiting_order)
    get api_order_path(other_order), as: :json
    assert_response :forbidden
  end

  # -- create --

  test 'create order with items and participants' do
    assert_difference('Order.count') do
      post api_orders_path, params: { order: {
        participant_ids: [ @admin.id ],
        order_items_attributes: [
          { article_id: @article.id, article_variant_id: @variant.id, quantity: 2, price: 10.50 }
        ]
      } }, as: :json
    end
    assert_response :created

    order = Order.last
    assert_nil order.sharing_type
    assert_equal 1, order.order_items.count
    assert_includes order.users, @user
    assert_includes order.users, @admin
  end

  test 'create order without participants includes current user' do
    assert_difference('Order.count') do
      post api_orders_path, params: { order: {
        order_items_attributes: [
          { article_id: @article.id, article_variant_id: @variant.id, quantity: 1, price: 10.00 }
        ]
      } }, as: :json
    end
    assert_response :created
    assert_includes Order.last.users, @user
  end

  # -- create with multiple items --

  test 'create order with multiple items' do
    phone = articles(:phone)
    phone_variant = article_variants(:phone_default)

    assert_difference('Order.count') do
      assert_difference('OrderItem.count', 2) do
        post api_orders_path, params: { order: {
          order_items_attributes: [
            { article_id: @article.id, article_variant_id: @variant.id, quantity: 1, price: 999.99 },
            { article_id: phone.id, article_variant_id: phone_variant.id, quantity: 3, price: 599.99 }
          ]
        } }, as: :json
      end
    end
    assert_response :created
    assert_equal 2, Order.last.order_items.count
  end

  # -- validation errors --

  test 'zero quantity returns unprocessable_entity' do
    assert_no_difference('Order.count') do
      post api_orders_path, params: { order: {
        order_items_attributes: [
          { article_id: @article.id, article_variant_id: @variant.id, quantity: 0, price: 10.00 }
        ]
      } }, as: :json
    end
    assert_response :unprocessable_entity
  end

  # -- authentication --

  test 'create requires authentication' do
    sign_out @user
    post api_orders_path, params: { order: {} }, as: :json
    assert_response :unauthorized
  end

  # -- update --

  test 'update order' do
    patch api_order_path(@order), params: { order: {} }, as: :json
    assert_response :success
  end
end
