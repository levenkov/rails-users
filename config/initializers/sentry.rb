if ENV['SENTRY_DSN'].present? and not Rails.env.test?
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']

    config.breadcrumbs_logger = %i[active_support_logger http_logger]

    config.traces_sample_rate = 0.1

    config.send_default_pii = false

    config.excluded_exceptions += %w[
      ActionController::RoutingError
      ActiveRecord::RecordNotFound
      Pundit::NotAuthorizedError
    ]
  end
end
