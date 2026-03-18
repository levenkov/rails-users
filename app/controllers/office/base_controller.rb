class Office::BaseController < ApplicationController
  layout 'office'

  before_action :authenticate_user!
  before_action :ensure_office_access

  private

  def ensure_office_access
    authorize :office, :access?
  end

  def user_not_authorized
    respond_to do |format|
      format.html do
        render html: '<h1>Access denied</h1><p>You do not have permission to access this page.</p>'.html_safe,
          status: :forbidden
      end
      format.json { render json: { error: 'Not authorized' }, status: :forbidden }
      format.any do
        render html: '<h1>Access denied</h1><p>You do not have permission to access this page.</p>'.html_safe,
          status: :forbidden
      end
    end
  end

  def current_market_ids
    @current_market_ids ||= current_user.markets.pluck(:id)
  end
  helper_method :current_market_ids
end
