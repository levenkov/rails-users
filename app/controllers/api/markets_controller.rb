class Api::MarketsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_market, only: %i[show update destroy]

  def index
    @markets = policy_scope(Market)
    render json: @markets
  end

  def show
    authorize @market
    render json: @market
  end

  def create
    @market = current_user.markets.build(market_params)
    authorize @market

    if @market.save
      render json: @market, status: :created
    else
      render json: { errors: @market.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize @market

    if @market.update(market_params)
      render json: @market
    else
      render json: { errors: @market.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @market
    @market.destroy!
    head :no_content
  end

  private

  def set_market
    @market = Market.find(params[:id])
  end

  def market_params
    params.require(:market).permit(:name, :logo, photos: [])
  end
end
