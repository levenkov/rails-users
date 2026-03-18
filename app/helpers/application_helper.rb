module ApplicationHelper
  def user_carts
    return [] unless current_user

    Cart.joins(:cart_participants)
        .where(cart_participants: { user_id: current_user.id })
        .open
        .includes(:owner, :cart_items)
  end
end
