class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern

  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  protected

  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && resource.role == 'admin'
      admin_users_path
    else
      super
    end
  end

  def user_not_authorized
    respond_to do |format|
      format.html { redirect_to root_path, alert: 'You do not have access to this page.' }
      format.json { render json: { error: 'Not authorized' }, status: :forbidden }
      format.any { redirect_to root_path, alert: 'You do not have access to this page.' }
    end
  end

  def record_not_found(exception)
    respond_to do |format|
      format.html { raise exception }
      format.json { render json: { error: exception.message }, status: :not_found }
      format.any { raise exception }
    end
  end
end
