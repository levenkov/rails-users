class SplittingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @order = Order.find(params[:order_id])
    authorize @order, :show_splitting?
  end
end
