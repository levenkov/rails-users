class OrderItemSplit < ApplicationRecord
  belongs_to :order_item
  belongs_to :user

  validates :share, presence: true, numericality: { greater_than: 0 }
end
