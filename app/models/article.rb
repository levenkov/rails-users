class Article < ApplicationRecord
  belongs_to :market
  has_many :article_variants, dependent: :destroy
  has_many :order_items, dependent: :destroy
  has_many :orders, through: :order_items
  has_many_attached :photos

  accepts_nested_attributes_for :article_variants, reject_if: :all_blank, allow_destroy: true

  scope :available, -> { where(unlimited: true).or(where('stock > 0')) }

  validates :title, presence: true

  def single_variant?
    article_variants.size == 1
  end

  def price_range
    prices = article_variants.map(&:price)
    [ prices.min, prices.max ]
  end

  def default_variant
    article_variants.first
  end
end
