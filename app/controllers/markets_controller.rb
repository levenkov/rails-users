class MarketsController < ApplicationController
  before_action :require_login

  def index
    @markets = Market.with_attached_photos.includes(:owner, :articles)
  end

  def show
    @market = Market.with_attached_photos.includes(:owner,
      articles: [ :article_variants, { photos_attachments: :blob } ]).find(params[:id])

    @market_carts = user_carts
      .where(market: @market)
      .left_joins(:cart_items)
      .group('carts.id')
      .order(Arel.sql('MAX(cart_items.created_at) DESC NULLS LAST'))

    cart = if params[:new_cart].present?
      nil
    elsif params[:cart_id].present?
      user_carts.find_by(id: params[:cart_id])
    else
      @market_carts.first
    end

    @new_cart = params[:new_cart].present?
    @selected_cart_id = cart&.id
    @cart_quantities = if cart
      cart.cart_items.where(user: current_user).each_with_object({}) do |ci, h|
        h[ci.article_variant_id] = ci.quantity
      end
    else
      {}
    end
  end

  private

  def user_carts
    Cart.joins(:cart_participants).where(cart_participants: { user_id: current_user.id }).open
  end

  def require_login
    return if user_signed_in?

    if User.exists?
      redirect_to new_user_session_path
    else
      redirect_to new_user_registration_path
    end
  end
end
