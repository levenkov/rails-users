class Api::Splitting::ParticipantsController < ApplicationController
  include OrderRenderable

  before_action :authenticate_user!
  before_action :set_order

  def create
    authorize @order, :manage_participants?

    user = User.find(params[:user_id])

    unless @order.users.exists?(user.id)
      @order.users << user
      @order.reset_approvals!
    end

    render json: order_json(@order.reload)
  end

  def destroy
    authorize @order, :manage_participants?

    user = User.find(params[:id])

    if @order.users.count <= 1
      render json: { errors: [ 'Cannot remove the last participant' ] }, status: :unprocessable_entity
      return
    end

    Order.transaction do
      @order.order_item_splits.where(user: user).destroy_all
      @order.split_approvals.where(user: user).destroy_all
      @order.users.delete(user)
      @order.reset_approvals!
    end

    render json: order_json(@order.reload)
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end
end
