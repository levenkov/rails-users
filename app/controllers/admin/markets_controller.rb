class Admin::MarketsController < Admin::BaseController
  before_action :set_market, only: %i[edit update destroy]

  def index
    @markets = Market.includes(:owner, :articles)
                     .with_attached_logo
                     .order(created_at: :desc)
                     .page(params[:page])
                     .per(20)
  end

  def new
    @market = Market.new
  end

  def create
    @market = Market.new(market_params)

    if @market.save
      redirect_to admin_markets_path, notice: "Market #{@market.name} has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @market.update(market_params)
      redirect_to admin_markets_path, notice: "Market #{@market.name} has been updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @market.destroy!
    redirect_to admin_markets_path, notice: "Market #{@market.name} has been deleted."
  end

  private

  def set_market
    @market = Market.find(params[:id])
  end

  def market_params
    params.require(:market).permit(:name, :owner_id, :logo, photos: [])
  end
end
