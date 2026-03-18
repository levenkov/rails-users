class MarketPolicy < ApplicationPolicy
  def index?
    user_active?
  end

  def show?
    user_active?
  end

  def create?
    user_active?
  end

  def update?
    user_active? && (owner? || user.admin?)
  end

  def destroy?
    user_active? && (owner? || user.admin?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  private

  def owner?
    record.owner_id == user.id
  end
end
