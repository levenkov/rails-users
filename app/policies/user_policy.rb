class UserPolicy < ApplicationPolicy
  def search?
    user_active?
  end

  def destroy?
    user_active? && user.admin? && record != user
  end

  def update?
    user_active? && user.admin?
  end

  def toggle_role?
    user_active? && user.admin? && record != user
  end

  def toggle_2fa?
    user_active? && user.admin?
  end

  def reset_progress?
    user_active? && user.admin?
  end
end
