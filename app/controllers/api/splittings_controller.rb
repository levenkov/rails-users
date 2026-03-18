class Api::SplittingsController < ApplicationController
  include OrderRenderable

  before_action :authenticate_user!
  before_action :set_order

  def show
    authorize @order, :show_splitting?
    render json: order_json(@order)
  end

  def update
    authorize @order, :update_splits?

    Order.transaction do
      @order.sharing_type = params[:sharing_type]
      OrderItemSplit.where(order_item_id: @order.order_item_ids).delete_all

      splits_params = params[:splits] || {}
      splits_params.each do |order_item_id, user_splits|
        item = @order.order_items.find(order_item_id)
        Array(user_splits).each do |split_data|
          item.order_item_splits.create!(
            user_id: split_data[:user_id],
            share: split_data[:share]
          )
        end
      end

      @order.save!
      @order.reset_approvals!
    end

    render json: order_json(@order.reload)
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end
end
