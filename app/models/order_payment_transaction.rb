class OrderPaymentTransaction < ApplicationRecord
  belongs_to :order
  belongs_to :user

  validates :amount, presence: true, numericality: { greater_than: 0 }

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :pending, -> { where(confirmed_at: nil) }

  def confirmed?
    confirmed_at.present?
  end
end
