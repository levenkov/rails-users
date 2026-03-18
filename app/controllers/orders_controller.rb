class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: %i[show archive]

  def index
    @orders = policy_scope(Order).includes(:order_items, :articles).order(created_at: :desc)
  end

  def show
    authorize @order
  end

  def new
    redirect_to carts_path
  end

  def checkout
    @cart = find_cart
    if @cart.nil? || @cart.cart_items.empty?
      redirect_to carts_path, alert: 'Your cart is empty.'
      return
    end
    if @cart.owner_id != current_user.id
      redirect_to cart_path(@cart), alert: 'Only the cart owner can checkout.'
      return
    end

    authorize Order.new, :create?
    load_cart_items
    load_cart_participants
  end

  def create
    @cart = find_cart
    if @cart.nil? || @cart.cart_items.empty?
      redirect_to carts_path, alert: 'Your cart is empty.'
      return
    end
    if @cart.owner_id != current_user.id
      redirect_to cart_path(@cart), alert: 'Only the cart owner can checkout.'
      return
    end

    @order = build_order_from_cart(@cart)
    @order.owner = current_user
    @order.users << current_user

    participant_ids = @cart.users.pluck(:id) |
                      Array(params.dig(:order, :participant_ids)).map(&:to_i)
    participant_ids -= [ current_user.id ]
    User.where(id: participant_ids).each { |u| @order.users << u }

    authorize @order

    if @order.save
      @cart.close!
      redirect_to order_path(@order), notice: 'Order created successfully.'
    else
      load_cart_items
      render :checkout, status: :unprocessable_entity
    end
  end

  def archive
    authorize @order

    result = OrderArchiveService.new(@order, current_user).call
    if result.success?
      redirect_to order_path(@order), notice: 'Order archived.'
    else
      redirect_to order_path(@order), alert: result.error
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def find_cart
    cart_id = params[:cart_id]
    scope = Cart.open.joins(:cart_participants).where(cart_participants: { user_id: current_user.id })
    if cart_id.present?
      scope.find_by(id: cart_id)
    else
      scope.first
    end
  end

  def build_order_from_cart(cart)
    order = Order.new(cart: cart)
    cart.cart_items.includes(article_variant: :article).each do |cart_item|
      variant = cart_item.article_variant
      order.order_items.build(
        article: variant.article,
        article_variant: variant,
        quantity: cart_item.quantity,
        price: variant.price,
        added_by_user_id: cart_item.user_id
      )
    end
    order
  end

  def load_cart_items
    @cart_items = @cart.cart_items.includes(article_variant: :article).map do |ci|
      variant = ci.article_variant
      {
        variant: variant, article: variant.article,
        quantity: ci.quantity, line_total: variant.price * ci.quantity
      }
    end
    @total = @cart_items.sum { |i| i[:line_total] }
  end

  def load_cart_participants
    @cart_participants = @cart.users.where.not(id: current_user.id).to_a
  end
end
