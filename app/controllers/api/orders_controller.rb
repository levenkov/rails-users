class Api::OrdersController < ApplicationController
  include OrderRenderable

  before_action :authenticate_user!
  before_action :set_order, only: %i[show update]

  def index
    @orders = policy_scope(Order)
    render json: @orders, include: :order_items
  end

  def show
    authorize @order
    render json: order_json(@order)
  end

  def create
    @order = Order.new(order_params)
    @order.users << current_user

    participant_ids = Array(params.dig(:order, :participant_ids)).map(&:to_i) - [ current_user.id ]
    participants = User.where(id: participant_ids)
    participants.each { |u| @order.users << u }

    authorize @order

    if @order.save
      render json: order_json(@order), status: :created
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize @order

    if @order.update(order_params)
      render json: order_json(@order)
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.fetch(:order, {}).permit(
      order_items_attributes: %i[article_id article_variant_id quantity price]
    )
  end
end
