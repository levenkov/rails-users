module OrderRenderable
  extend ActiveSupport::Concern

  private

  def order_json(order)
    order_items = order.order_items.includes(:article, :article_variant, order_item_splits: :user)

    {
      id: order.id,
      state: order.state,
      sharing_type: order.sharing_type,
      created_at: order.created_at,
      updated_at: order.updated_at,
      order_items: order_items.map do |item|
        {
          id: item.id,
          article_id: item.article_id,
          article_title: item.article.title,
          article_variant_id: item.article_variant_id,
          article_variant_name: item.article_variant.name,
          quantity: item.quantity,
          price: item.price.to_f,
          order_item_splits: item.order_item_splits.map do |split|
            {
              id: split.id,
              user_id: split.user_id,
              user_name: split.user.name,
              share: split.share.to_f
            }
          end
        }
      end,
      users: order.users.map { |u| { id: u.id, name: u.name } },
      split_approvals: order.split_approvals.map do |a|
        { user_id: a.user_id, approved_at: a.approved_at }
      end,
      suggested_splits: suggested_splits_for(order)
    }
  end

  def suggested_splits_for(order)
    return nil if order.cart_id.blank?
    return nil if order.order_item_splits.exists?

    suggestions = {}
    order.order_items.each do |item|
      next unless item.added_by_user_id
      suggestions[item.id] = [ { user_id: item.added_by_user_id, share: 1 } ]
    end
    suggestions.presence
  end
end
