class Admin::ArticlesController < Admin::BaseController
  before_action :set_market
  before_action :set_article, only: %i[edit update destroy]

  def index
    @articles = @market.articles
                       .includes(:article_variants)
                       .with_attached_photos
                       .order(created_at: :desc)
                       .page(params[:page])
                       .per(20)
  end

  def new
    @article = @market.articles.build
    @article.article_variants.build
  end

  def create
    @article = @market.articles.build(article_params)

    if @article.save
      redirect_to admin_market_articles_path(@market), notice: "Article #{@article.title} has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @article.update(article_params)
      redirect_to admin_market_articles_path(@market), notice: "Article #{@article.title} has been updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy!
    redirect_to admin_market_articles_path(@market), notice: "Article #{@article.title} has been deleted."
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
