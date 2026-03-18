class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :article
  belongs_to :article_variant, optional: true
  belongs_to :added_by_user, class_name: 'User', optional: true
  has_many :order_item_splits, dependent: :destroy
  accepts_nested_attributes_for :order_item_splits, reject_if: :all_blank

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
