class Admin::OrdersController < Admin::BaseController
  before_action :set_order, only: %i[show transition]

  def index
    @orders = Order.includes(:users, order_items: :article)
                   .order(created_at: :desc)

    @orders = @orders.where(state: params[:state]) if params[:state].present?

    @orders = @orders.page(params[:page]).per(20)
  end

  def show
    @order_items = @order.order_items.includes(article: :market, order_item_splits: :user)
    @payments = @order.order_payment_transactions.includes(:user)
    @approvals = @order.split_approvals.includes(:user)
  end

  def transition
    event = params[:event]

    unless %w[start_preparing wait_for_delivery start_delivery finish].include?(event)
      redirect_to admin_order_path(@order), alert: 'Invalid transition.'
      return
    end

    if @order.send("may_#{event}?") && @order.send("#{event}!")
      redirect_to admin_order_path(@order), notice: "Order ##{@order.id} transitioned to #{@order.state.humanize}."
    else
      redirect_to admin_order_path(@order), alert: 'Cannot perform this transition.'
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end
end
