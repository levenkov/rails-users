class OfficePolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def access?
    user&.present? && !user.disabled && user.markets.exists?
  end
end
