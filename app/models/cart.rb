class Cart < ApplicationRecord
  belongs_to :owner, class_name: 'User'
  belongs_to :market
  has_many :cart_items, dependent: :destroy
  has_many :cart_participants, dependent: :destroy
  has_many :users, through: :cart_participants
  has_one :order

  scope :open, -> { where(closed: false) }
  scope :closed, -> { where(closed: true) }

  def close!
    update!(closed: true)
  end

  def items_count
    cart_items.sum(:quantity)
  end
end
