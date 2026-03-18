require 'test_helper'

class Api::MarketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @market = markets(:one)
    sign_in @user
  end

  test 'index returns markets' do
    get api_markets_path, as: :json
    assert_response :success
  end

  test 'show returns a market' do
    get api_market_path(@market), as: :json
    assert_response :success
  end

  test 'create market' do
    assert_difference('Market.count') do
      post api_markets_path, params: { market: { name: 'New Market' } }, as: :json
    end
    assert_response :created
  end

  test 'create market without name fails' do
    post api_markets_path, params: { market: { name: '' } }, as: :json
    assert_response :unprocessable_entity
  end

  test 'update own market' do
    patch api_market_path(@market), params: { market: { name: 'Updated' } }, as: :json
    assert_response :success
    assert_equal 'Updated', @market.reload.name
  end

  test 'destroy own market' do
    assert_difference('Market.count', -1) do
      delete api_market_path(@market), as: :json
    end
    assert_response :no_content
  end

  test 'cannot update other users market' do
    other_market = markets(:two)
    patch api_market_path(other_market), params: { market: { name: 'Hacked' } }, as: :json
    assert_response :forbidden
  end
end
