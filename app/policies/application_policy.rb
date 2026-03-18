# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user_active? && false
  end

  def show?
    user_active? && false
  end

  def create?
    user_active? && false
  end

  def new?
    create?
  end

  def update?
    user_active? && false
  end

  def edit?
    update?
  end

  def destroy?
    user_active? && false
  end

  private

  def user_active?
    user.present? && !user.disabled
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
