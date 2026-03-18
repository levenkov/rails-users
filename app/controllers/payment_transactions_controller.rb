class PaymentTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order

  def new
    authorize @order, :create_payment?
    remaining = @order.total - @order.total_paid
    @transaction = @order.order_payment_transactions.build(amount: [ remaining, 0 ].max)
  end

  def create
    authorize @order, :create_payment?

    @transaction = @order.order_payment_transactions.build(
      user: current_user,
      amount: params[:order_payment_transaction][:amount],
      comment: params[:order_payment_transaction][:comment]
    )

    if @transaction.save
      redirect_to order_path(@order), notice: 'Payment recorded.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @order, :create_payment?

    @transaction = @order.order_payment_transactions.find(params[:id])

    if @order.archived?
      redirect_to order_path(@order), alert: 'Cannot revoke payments on an archived order.'
      return
    end

    if @transaction.user_id != current_user.id
      redirect_to order_path(@order), alert: 'Only the payment author can revoke.'
      return
    end

    if @transaction.confirmed?
      redirect_to order_path(@order), alert: 'Cannot revoke a confirmed payment.'
      return
    end

    @transaction.destroy!
    redirect_to order_path(@order), notice: 'Payment revoked.'
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end
end
