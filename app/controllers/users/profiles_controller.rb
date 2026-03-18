# frozen_string_literal: true

class Users::ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    sleep 1 if Rails.env.development?

    respond_to do |format|
      format.html do
        @balances = compute_balances
        @recent_payments = FinancialTransaction
          .where(sender_id: current_user.id)
          .or(FinancialTransaction.where(receiver_id: current_user.id))
          .includes(:sender, :receiver)
          .order(created_at: :desc)
          .limit(10)
      end
      format.json
    end
  end

  private

  def compute_balances
    other_user_ids = Order.joins(:users)
      .where(orders_users: { user_id: current_user.id })
      .joins("INNER JOIN orders_users ou2 ON ou2.order_id = orders.id AND ou2.user_id != #{current_user.id}")
      .pluck('ou2.user_id')
      .uniq

    ft_user_ids = FinancialTransaction
      .where(sender_id: current_user.id).or(FinancialTransaction.where(receiver_id: current_user.id))
      .pluck(:sender_id, :receiver_id).flatten.uniq - [ current_user.id ]

    all_user_ids = (other_user_ids + ft_user_ids).uniq
    users_by_id = User.where(id: all_user_ids).index_by(&:id)

    balances = []
    all_user_ids.each do |uid|
      other = users_by_id[uid]
      next unless other

      balance = UserPairBalanceCalculator.new(current_user, other).call
      low_id, _high_id = [ current_user.id, uid ].sort

      # balance positive = high owes low
      # We want: positive = current_user owes other
      if current_user.id == low_id
        display_amount = -balance # low is current_user, positive balance means other owes us
      else
        display_amount = balance # high is current_user, positive balance means we owe low
      end

      next if display_amount.zero?

      balances << { user: other, amount: display_amount }
    end

    balances.sort_by { |b| [ -b[:amount].abs ] }
  end
end
