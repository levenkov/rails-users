# frozen_string_literal: true

Devise.setup do |config|
  # rubocop:disable Layout/LineLength
  config.secret_key =
    '2d52f12473f90222205ec7a287a887c7d599a5ddd7649a1685147e04e403238110933709bfaaf3ed3ceee074d7079b665f2d49e125eb4675ab6d2d12c9843a62'
  # rubocop:enable Layout/LineLength

  config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'

  require 'devise/orm/active_record'

  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]
  config.skip_session_storage = [ :http_auth ]
  config.stretches = Rails.env.test? ? 1 : 12

  # Send a notification to the original email when the user's email is changed.
  # config.send_email_changed_notification = false

  # Send a notification email when the user's password is changed.
  # config.send_password_change_notification = false

  config.reconfirmable = true
  config.expire_all_remember_me_on_sign_out = true
  config.remember_for = 1.month
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours

  config.navigational_formats = %i[html turbo_stream]

  config.sign_out_via = :delete

  # ==> OmniAuth
  # Add a new OmniAuth provider. Check the wiki for more information on setting
  # up on your models and hooks.
  # config.omniauth :github, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'
  # config.omniauth :google_oauth2,
  #                Rails.application.credentials.google_oauth_client_id,
  #                Rails.application.credentials.google_oauth_client_secret,
  #                {
  #                  name: 'google_oauth2',
  #                  scope: 'email,profile',
  #                  prompt: 'select_account',
  #                  image_aspect_ratio: 'square',
  #                  image_size: 50
  #                }

  config.omniauth :google_oauth2,
    Rails.application.credentials.oauth2&.google&.ios&.client_id,
    {
      name: 'google_oauth2_ios',
      scope: 'email,profile',
      prompt: 'select_account',
      image_aspect_ratio: 'square',
      image_size: 50
    }

  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  config.jwt do |jwt|
    jwt.secret = Rails.application.credentials.devise_jwt_secret_key
    jwt.expiration_time = 1.month.to_i

    jwt.dispatch_requests += [
      [ 'POST', %r{^/users$} ],
      [ 'POST', %r{^/users/auth/google_oauth2/mobile$} ],
      [ 'POST', %r{^/users/auth/google_oauth2/register_with_saved_token$} ]
    ]
  end
end
