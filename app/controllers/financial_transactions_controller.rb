class FinancialTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: %i[edit update destroy]

  def index
    @transactions = FinancialTransaction
      .where(sender_id: current_user.id)
      .or(FinancialTransaction.where(receiver_id: current_user.id))
      .includes(:sender, :receiver)
      .order(created_at: :desc)
  end

  def new
    @transaction = FinancialTransaction.new
    @users = User.where.not(id: current_user.id).order(:name)
  end

  def create
    @transaction = FinancialTransaction.new(transaction_params)
    @transaction.sender = current_user

    if @transaction.save
      redirect_to users_me_path, notice: 'Payment recorded.'
    else
      @users = User.where.not(id: current_user.id).order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.where.not(id: current_user.id).order(:name)
  end

  def update
    if @transaction.update(transaction_params)
      redirect_to financial_transactions_path, notice: 'Payment updated.'
    else
      @users = User.where.not(id: current_user.id).order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy!
    redirect_back fallback_location: financial_transactions_path, notice: 'Payment deleted.'
  end

  private

  def set_transaction
    @transaction = current_user.sent_financial_transactions.find(params[:id])
  end

  def transaction_params
    params.require(:financial_transaction).permit(:receiver_id, :amount, :description)
  end
end
