require 'test_helper'

class Api::ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @market = markets(:one)
    @article = articles(:laptop)
    sign_in @user
  end

  test 'index returns articles for market' do
    get api_market_articles_path(@market), as: :json
    assert_response :success
  end

  test 'show returns an article' do
    get api_market_article_path(@market, @article), as: :json
    assert_response :success
  end

  test 'create article' do
    assert_difference('Article.count') do
      post api_market_articles_path(@market), params: { article: {
        title: 'New Article',
        article_variants_attributes: [ { price: 10.00 } ]
      } }, as: :json
    end
    assert_response :created
  end

  test 'update own market article' do
    patch api_market_article_path(@market, @article), params: { article: { title: 'Updated' } }, as: :json
    assert_response :success
    assert_equal 'Updated', @article.reload.title
  end

  test 'destroy own market article' do
    assert_difference('Article.count', -1) do
      delete api_market_article_path(@market, @article), as: :json
    end
    assert_response :no_content
  end
end
