class CartParticipant < ApplicationRecord
  belongs_to :cart
  belongs_to :user

  validates :user_id, uniqueness: { scope: :cart_id }
end
