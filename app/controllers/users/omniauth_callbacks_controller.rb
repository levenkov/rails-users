# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  respond_to :html, :json
  skip_before_action :verify_authenticity_token, only: %i[google_oauth2 google_mobile]

  def google_oauth2
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication

      set_flash_message(:notice, :success, kind: 'Google') if is_navigational_format?
    else
      redirect_to new_user_registration_url,
        alert: 'There was a problem signing you in through Google. Please register or try signing in later.'
    end
  end

  def google_mobile
    id_token = params[:id_token]
    action = params[:action_type]&.to_sym || :login

    if id_token.blank?
      return render 'api/shared/error', locals: { error: 'Missing Google ID token' }, status: :bad_request
    end

    verified_data = verify_google_id_token(id_token)

    if verified_data.nil?
      return render 'api/shared/error', locals: { error: 'Invalid Google ID token' }, status: :unauthorized
    end

    uid = verified_data['sub']
    email = verified_data['email']
    name = verified_data['name']
    provider = 'google_oauth2_ios'

    case action
    when :registration
      handle_google_registration(provider, uid, email, name)
    when :login
      handle_google_login(provider, uid, email, name, id_token)
    else
      render 'api/shared/error', locals: { error: 'Invalid action parameter' }, status: :bad_request
    end
  end

  def register_with_saved_token
    registration_token = params[:registration_token]

    if registration_token.blank?
      return render 'api/shared/error', locals: { error: 'Missing registration token' }, status: :bad_request
    end

    redis_key = "google_signin_no_user_#{registration_token}"
    stored_id_token = redis.get(redis_key)

    if stored_id_token.nil?
      return render 'api/shared/error', locals: { error: 'Invalid or expired registration token' },
        status: :unauthorized
    end

    redis.del(redis_key)

    verified_data = verify_google_id_token(stored_id_token)

    if verified_data.nil?
      return render 'api/shared/error', locals: { error: 'Invalid stored Google ID token' }, status: :unauthorized
    end

    uid = verified_data['sub']
    email = verified_data['email']
    name = verified_data['name']
    provider = 'google_oauth2_ios'

    handle_google_registration(provider, uid, email, name)
  end

  def failure
    redirect_to new_user_session_path, alert: 'Authentication failed.'
  end

  protected

  def after_omniauth_failure_path_for(scope)
    new_user_session_path
  end

  private

  def handle_google_login(provider, uid, email, name, id_token)
    user_oauth = UserOauth.find_by(provider: provider, uid: uid)

    if user_oauth
      user = user_oauth.user

      if user.disabled
        return render 'api/shared/error', locals: { error: I18n.t('devise.failure.disabled') }, status: :unauthorized
      end

      sign_in(:user, user, event: :authentication)

      token = request.env['warden-jwt_auth.token']
      render 'users/sessions/create', locals: { resource: user, token: token }
    else
      registration_token = SecureRandom.hex(32)
      redis_key = "google_signin_no_user_#{registration_token}"
      redis.set(redis_key, id_token, ex: 300) # 5 minutes expiration

      render 'users/sessions/no_such_user', locals: {
        registration_token: registration_token,
        email: email,
        name: name
      }
    end
  end

  def handle_google_registration(provider, uid, email, name)
    existing_user = User.find_by(email: email)
    if existing_user
      return render 'api/shared/error', locals: { error: 'User with this email already exists' }, status: :conflict
    end

    existing_oauth = UserOauth.find_by(provider: provider, uid: uid)
    if existing_oauth
      return render 'api/shared/error', locals: { error: 'This Google account is already connected to another user' },
        status: :conflict
    end

    user = User.new(
      email: email,
      name: name,
      password: Devise.friendly_token[0, 20]  # Generate random password
    )

    if user.save
      user_oauth = user.user_oauths.create!(
        provider: provider,
        uid: uid,
        email: email,
        name: name
      )

      sign_in(:user, user, event: :authentication)

      token = request.env['warden-jwt_auth.token']
      render 'users/sessions/create', locals: { resource: user, token: token }
    else
      render 'api/shared/error', locals: { error: user.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def verify_google_id_token(id_token)
    require 'jwt'
    require 'net/http'

    uri = URI('https://www.googleapis.com/oauth2/v3/certs')
    response = Net::HTTP.get_response(uri)
    google_keys = JSON.parse(response.body)

    decoded_token = nil
    google_keys['keys'].each do |key|
      begin
        decoded_token = JWT.decode(id_token, JWT::JWK.new(key).public_key, true, { algorithm: 'RS256' })
        break
      rescue JWT::DecodeError
        next
      end
    end

    return nil if decoded_token.nil?
    decoded_token[0]
  end

  def redis
    @redis ||= Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379/0')
  end
end
