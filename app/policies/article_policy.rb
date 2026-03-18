class ArticlePolicy < ApplicationPolicy
  def index?
    user_active?
  end

  def show?
    user_active?
  end

  def create?
    user_active? && (market_owner? || user.admin?)
  end

  def update?
    user_active? && (market_owner? || user.admin?)
  end

  def destroy?
    user_active? && (market_owner? || user.admin?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  private

  def market_owner?
    record.market.owner_id == user.id
  end
end
