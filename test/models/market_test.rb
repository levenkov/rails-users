require 'test_helper'

class MarketTest < ActiveSupport::TestCase
  test 'valid market' do
    market = markets(:one)
    assert market.valid?
  end

  test 'requires name' do
    market = Market.new(owner: users(:regular))
    assert_not market.valid?
    assert_includes market.errors[:name], "can't be blank"
  end

  test 'belongs to owner' do
    market = markets(:one)
    assert_equal users(:regular), market.owner
  end

  test 'has many articles' do
    market = markets(:one)
    assert_includes market.articles, articles(:laptop)
  end
end
