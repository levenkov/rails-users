class OrderPolicy < ApplicationPolicy
  def index?
    user_active?
  end

  def show?
    user_active? && (member? || user.admin?)
  end

  def create?
    user_active?
  end

  def update?
    user_active? && (member? || user.admin?)
  end

  def show_splitting?
    user_active? && (member? || user.admin?)
  end

  def update_splits?
    user_active? && (member? || user.admin?)
  end

  def approve_splits?
    user_active? && member?
  end

  def manage_participants?
    user_active? && (member? || user.admin?)
  end

  def create_payment?
    user_active? && (member? || user.admin?)
  end

  def archive?
    user_active? && record.finished? && record.owner_id == user.id
  end

  def confirm_payment?
    user_active? && (market_owner? || user.admin?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.joins(:users).where(orders_users: { user_id: user.id })
      end
    end
  end

  private

  def member?
    record.users.exists?(user.id)
  end

  def market_owner?
    record.articles.joins(:market).where(markets: { owner_id: user.id }).exists?
  end
end
