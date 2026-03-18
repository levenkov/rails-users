class UserPairBalance < ApplicationRecord
  belongs_to :order
  belongs_to :user_low, class_name: 'User'
  belongs_to :user_high, class_name: 'User'

  validates :balance, presence: true

  def self.for_pair(user_a, user_b)
    low_id, high_id = [ user_a.id, user_b.id ].sort
    where(user_low_id: low_id, user_high_id: high_id)
  end
end
