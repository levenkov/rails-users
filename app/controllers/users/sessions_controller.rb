# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  respond_to :html, :json

  helper_method :token

  def new
    if user_signed_in?
      redirect_to root_path
      return
    end

    if User.count.zero?
      redirect_to new_user_registration_path
      return
    end

    self.resource = resource_class.new
    clean_up_passwords(resource)
    yield resource if block_given?
    respond_with(resource, serialize_options(resource))
  end

  def create
    resource_params = sign_in_params
    self.resource = User.find_for_database_authentication(email: resource_params[:email])

    unless resource&.valid_password?(resource_params[:password])
      warden.custom_failure!
      error_message = I18n.t('devise.failure.invalid', authentication_keys: User.authentication_keys.join('/'))

      respond_to do |format|
        format.html do
          redirect_to new_session_path(resource_name), alert: error_message
        end
        format.json do
          render(
            'errors/authorization_failed',
            locals: { error_message: error_message },
            status: :unauthorized,
          )
        end
      end
      return
    end

    unless resource.active_for_authentication?
      warden.custom_failure!
      error_message = I18n.t("devise.failure.#{resource.inactive_message}",
        authentication_keys: User.authentication_keys.join('/'))

      respond_to do |format|
        format.html do
          redirect_to new_session_path(resource_name), alert: error_message
        end
        format.json do
          render(
            'errors/authorization_failed',
            locals: { error_message: error_message },
            status: :unauthorized,
          )
        end
      end
      return
    end

    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?

    respond_with resource, location: after_sign_in_path_for(resource)
  end

  private

  def token
    request.env['warden-jwt_auth.token']
  end

  def sign_in_params
    params.require(:user).permit(:email, :password)
  rescue ActionController::ParameterMissing
    {}
  end
end
