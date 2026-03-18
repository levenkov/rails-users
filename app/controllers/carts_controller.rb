class CartsController < ApplicationController
  before_action :authenticate_user!

  def index
    all = all_user_carts.includes(:owner, :market, :cart_participants, cart_items: :article_variant)
    @open_carts = all.open
    @closed_carts = all.closed
  end

  def show
    @user_carts = user_carts.includes(:owner, :market, :cart_items)
    @cart = all_user_carts.find_by(id: params[:id])
    redirect_to carts_path and return unless @cart
    load_cart_data
  end

  def add
    variant = ArticleVariant.find(params[:article_variant_id])
    article = variant.article
    raise ActiveRecord::RecordNotFound unless Article.available.exists?(article.id)

    cart = if params[:new_cart].present?
      nil
    elsif params[:cart_id].present?
      user_carts.find_by(id: params[:cart_id])
    else
      user_carts.find_by(market: article.market)
    end
    cart ||= current_user.my_carts.create!(market: article.market)
    cart.users << current_user unless cart.users.exists?(current_user.id)

    cart_item = cart.cart_items.find_or_initialize_by(article_variant: variant, user: current_user)
    if cart_item.new_record?
      cart_item.quantity = params[:quantity]&.to_i || 1
    else
      cart_item.quantity += (params[:quantity]&.to_i || 1)
    end

    if cart_item.save
      redirect_to market_path(article.market, cart_id: cart.id),
        notice: "#{article.title} added to cart."
    else
      redirect_back fallback_location: market_path(article.market),
        alert: cart_item.errors.full_messages.join(', '),
        status: :unprocessable_entity
    end
  end

  def remove
    variant = ArticleVariant.find(params[:article_variant_id])
    article = variant.article

    cart = if params[:cart_id].present?
      user_carts.find_by(id: params[:cart_id])
    end
    cart ||= user_carts.find_by(market: article.market)
    return redirect_back(fallback_location: market_path(article.market)) unless cart

    cart_item = cart.cart_items.find_by(article_variant: variant, user: current_user)
    if cart_item
      if cart_item.quantity > 1
        cart_item.update!(quantity: cart_item.quantity - 1)
      else
        cart_item.destroy!
      end
    end

    redirect_back fallback_location: market_path(article.market)
  end

  def update
    @cart = user_carts.find(params[:id])

    quantities = params[:quantities] || {}
    quantities.each do |item_id, qty|
      cart_item = @cart.cart_items.find_by(id: item_id)
      next unless cart_item

      if qty.to_i > 0
        cart_item.update!(quantity: qty.to_i)
      else
        cart_item.destroy!
      end
    end

    redirect_to cart_path(@cart), notice: 'Cart updated.'
  end

  def destroy
    @cart = current_user.my_carts.find(params[:id])
    @cart.destroy!
    redirect_to carts_path, notice: 'Cart deleted.'
  end

  def copy
    source = all_user_carts.closed.find(params[:id])

    new_cart = current_user.my_carts.create!(market: source.market)
    new_cart.users << current_user

    source.cart_items.each do |ci|
      new_cart.cart_items.create!(
        article_variant: ci.article_variant,
        user: current_user,
        quantity: ci.quantity
      )
    end

    redirect_to cart_path(new_cart), notice: 'Cart copied successfully.'
  end

  def add_participant
    @cart = user_carts.find(params[:id])
    user = User.find(params[:user_id])
    @cart.users << user unless @cart.users.exists?(user.id)
    render json: { id: user.id, name: user.name }
  end

  def remove_participant
    @cart = user_carts.find(params[:id])
    user_id = params[:user_id].to_i
    @cart.cart_participants.find_by(user_id: user_id)&.destroy
    head :no_content
  end

  def toggle_ready
    @cart = user_carts.find(params[:id])
    cp = @cart.cart_participants.find_by!(user: current_user)
    cp.update!(ready: !cp.ready)
    redirect_to cart_path(@cart)
  end

  private

  def all_user_carts
    Cart.joins(:cart_participants).where(cart_participants: { user_id: current_user.id })
  end

  def user_carts
    all_user_carts.open
  end

  def load_cart_data
    items = @cart.cart_items.includes(:user, article_variant: { article: [ photos_attachments: :blob ] })
    grouped = items.group_by(&:user).map do |user, cart_items|
      mapped = cart_items.map do |ci|
        variant = ci.article_variant
        {
          id: ci.id, variant: variant, article: variant.article,
          quantity: ci.quantity, line_total: variant.price * ci.quantity
        }
      end
      { user: user, items: mapped, subtotal: mapped.sum { |i| i[:line_total] } }
    end
    @grouped_cart_items = grouped.sort_by { |g| g[:user] == current_user ? 0 : 1 }
    @total = grouped.sum { |g| g[:subtotal] }
    @cart_participants = @cart.cart_participants.includes(:user)
    @participants = @cart_participants.map(&:user)
    @ready_user_ids = @cart_participants.select(&:ready?).map(&:user_id).to_set
  end
end
