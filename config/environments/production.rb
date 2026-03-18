require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.headers = { 'cache-control' => "public, max-age=#{1.year.to_i}" }

  config.assume_ssl = ENV.fetch('RAILS_ASSUME_SSL', 'false') == 'true'
  config.force_ssl = false

  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')
  config.silence_healthcheck_path = '/up'

  config.active_support.report_deprecations = false
  config.cache_store = :memory_store

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]

  config.active_storage.service = :production

  # ActionMailer configuration
  config.action_mailer.default_url_options = { host: config.app_host }
  config.action_mailer.delivery_method = :gmail_oauth2
  config.action_mailer.smtp_settings = {
    address: 'smtp.gmail.com',
    port: 587,
    domain: config.app_host
  }
  config.action_mailer.default_options = {
    from: Rails.application.credentials.dig(:google, :mailer, :from)
  }
end
