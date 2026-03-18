require 'test_helper'

class ArticleTest < ActiveSupport::TestCase
  test 'valid article' do
    article = articles(:laptop)
    assert article.valid?
  end

  test 'requires title' do
    article = Article.new(market: markets(:one))
    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"
  end

  test 'belongs to market' do
    article = articles(:laptop)
    assert_equal markets(:one), article.market
  end
end
