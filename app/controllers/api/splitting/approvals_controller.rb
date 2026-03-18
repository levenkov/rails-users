class Api::Splitting::ApprovalsController < ApplicationController
  include OrderRenderable

  before_action :authenticate_user!
  before_action :set_order

  def create
    authorize @order, :approve_splits?

    unless @order.splits_configured?
      render json: { errors: [ 'Splits must be configured before approving' ] }, status: :unprocessable_entity
      return
    end

    @order.split_approvals.find_or_create_by!(user: current_user) do |approval|
      approval.approved_at = Time.current
    end

    render json: order_json(@order.reload)
  end

  def destroy
    authorize @order, :approve_splits?

    @order.split_approvals.where(user: current_user).destroy_all
    render json: order_json(@order.reload)
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end
end
