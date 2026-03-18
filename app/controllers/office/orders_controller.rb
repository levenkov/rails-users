class Office::OrdersController < Office::BaseController
  before_action :set_order, only: %i[show transition confirm_payment]

  def index
    @orders = scoped_orders
                .includes(:users, order_items: :article)
                .order(created_at: :desc)

    @orders = @orders.where(state: params[:state]) if params[:state].present?

    @orders = @orders.page(params[:page]).per(20)
  end

  def show
    @order_items = @order.order_items.includes(article: :market, order_item_splits: :user)
    @payments = @order.order_payment_transactions.includes(:user)
    @approvals = @order.split_approvals.includes(:user)
  end

  def confirm_payment
    if @order.archived?
      redirect_to office_order_path(@order), alert: 'Cannot confirm payments on an archived order.'
      return
    end

    transaction = @order.order_payment_transactions.find(params[:payment_id])
    transaction.update!(confirmed_at: Time.current)
    redirect_to office_order_path(@order), notice: 'Payment confirmed.'
  end

  def transition
    event = params[:event]

    unless %w[start_preparing wait_for_delivery start_delivery finish].include?(event)
      redirect_to office_order_path(@order), alert: 'Invalid transition.'
      return
    end

    if @order.send("may_#{event}?") && @order.send("#{event}!")
      redirect_to office_order_path(@order), notice: "Order ##{@order.id} transitioned to #{@order.state.humanize}."
    else
      redirect_to office_order_path(@order), alert: 'Cannot perform this transition.'
    end
  end

  private

  def set_order
    @order = scoped_orders.find(params[:id])
  end

  def scoped_orders
    Order.joins(order_items: :article)
         .where(articles: { market_id: current_market_ids })
         .distinct
  end
end
