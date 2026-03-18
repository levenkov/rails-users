class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :article_variant
  belongs_to :user

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :article_variant_id, uniqueness: { scope: %i[cart_id user_id] }
  validate :variant_belongs_to_cart_market

  private

  def variant_belongs_to_cart_market
    return unless cart && article_variant

    if article_variant.article.market_id != cart.market_id
      errors.add(:article_variant, 'must belong to the same market as the cart')
    end
  end
end
