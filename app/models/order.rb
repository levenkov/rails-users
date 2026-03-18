class Order < ApplicationRecord
  include AASM

  SHARING_TYPES = %w[share percent amount].freeze

  belongs_to :cart, optional: true
  belongs_to :owner, class_name: 'User', optional: true
  has_and_belongs_to_many :users
  has_many :order_items, dependent: :destroy
  accepts_nested_attributes_for :order_items, reject_if: :all_blank, allow_destroy: true
  has_many :order_item_splits, through: :order_items
  has_many :articles, through: :order_items
  has_many :order_payment_transactions, dependent: :destroy
  has_many :split_approvals, dependent: :destroy
  has_many :user_pair_balances, dependent: :destroy

  validates :sharing_type, inclusion: { in: SHARING_TYPES }, allow_nil: true

  aasm column: :state, enum: false do
    state :submitted, initial: true
    state :preparing
    state :delivery_waiting
    state :in_delivery
    state :finished

    event :start_preparing do
      transitions from: :submitted, to: :preparing
    end

    event :wait_for_delivery do
      transitions from: :preparing, to: :delivery_waiting
    end

    event :start_delivery do
      transitions from: :delivery_waiting, to: :in_delivery
    end

    event :finish do
      transitions from: :in_delivery, to: :finished
    end
  end

  def all_participants_approved?
    splits_configured? && users.count > 0 &&
      split_approvals.count == users.count
  end

  def user_approved?(user)
    split_approvals.exists?(user: user)
  end

  def splits_configured?
    sharing_type.present? && order_item_splits.exists?
  end

  def reset_approvals!
    split_approvals.destroy_all
  end

  def total
    order_items.sum('price * quantity')
  end

  def total_paid
    order_payment_transactions.confirmed.sum(:amount)
  end

  def fully_paid?
    total_paid >= total
  end

  def archived?
    archived_at.present?
  end
end
