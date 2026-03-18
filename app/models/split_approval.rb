class SplitApproval < ApplicationRecord
  belongs_to :order
  belongs_to :user

  validates :approved_at, presence: true
  validates :user_id, uniqueness: { scope: :order_id }
end
