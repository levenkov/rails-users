class ApplicationMailer < ActionMailer::Base
  default from: -> { default_from_email }
  layout 'mailer'

  private

  def self.default_from_email
    Rails.application.credentials.dig(:google, :mailer, :from) || 'from@example.com'
  end

  def default_from_email
    self.class.default_from_email
  end
end
