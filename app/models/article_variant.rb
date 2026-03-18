class ArticleVariant < ApplicationRecord
  belongs_to :article
  has_many :order_items, dependent: :nullify

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :name, uniqueness: { scope: :article_id }, allow_nil: true
end
