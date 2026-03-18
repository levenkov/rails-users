class Api::ArticlesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_market
  before_action :set_article, only: %i[show update destroy]

  def index
    @articles = policy_scope(@market.articles)
    render json: @articles
  end

  def show
    authorize @article
    render json: @article
  end

  def create
    @article = @market.articles.build(article_params)
    authorize @article

    if @article.save
      render json: @article, status: :created
    else
      render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize @article

    if @article.update(article_params)
      render json: @article
    else
      render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @article
    @article.destroy!
    head :no_content
  end

  private

  def set_market
    @market = Market.find(params[:market_id])
  end

  def set_article
    @article = @market.articles.find(params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :description, :unlimited, :stock, photos: [],
      article_variants_attributes: %i[id name price _destroy])
  end
end
