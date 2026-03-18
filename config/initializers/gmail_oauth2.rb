require 'net/smtp'
require 'gmail_xoauth'


module GmailOAuth2Delivery
  SmtpSettings = Data.define(:address, :port, :domain)

  class DeliveryMethod
    def initialize(settings = {})
      # No longer need to store settings, will read from ActionMailer::Base.smtp_settings
    end

    def deliver!(mail)
      refresh_token = mailer_credentials.dig(:refresh_token)
      client_id = mailer_credentials.dig(:client_id)
      client_secret = mailer_credentials.dig(:client_secret)
      from_email = mailer_credentials.dig(:from)

      access_token = get_access_token(client_id, client_secret, refresh_token)

      smtp = Net::SMTP.new(settings.address, settings.port)
      smtp.enable_starttls_auto
      smtp.start(settings.domain, from_email, access_token, :xoauth2) do |smtp_conn|
        smtp_conn.send_message(mail.encoded, mail.from.first || from_email, mail.destinations)
      end
    end

    private

    def mailer_credentials
      Rails.application.credentials.dig(:google, :mailer)
    end

    def settings
      smtp_settings = ActionMailer::Base.smtp_settings

      SmtpSettings.new(
        address: smtp_settings.fetch(:address, 'smtp.gmail.com'),
        port: smtp_settings.fetch(:port, 587),
        domain: smtp_settings.fetch(:domain, 'localhost')
      )
    end

    def get_access_token(client_id, client_secret, refresh_token)
      uri = URI('https://oauth2.googleapis.com/token')
      res = Net::HTTP.post_form(uri,
        'client_id' => client_id,
        'client_secret' => client_secret,
        'refresh_token' => refresh_token,
        'grant_type' => 'refresh_token'
      )

      if res.is_a?(Net::HTTPSuccess)
        token_data = JSON.parse(res.body)
        token_data['access_token']
      else
        raise "Failed to get access token: #{res.body}"
      end
    end
  end
end

# Add the delivery method
ActionMailer::Base.add_delivery_method :gmail_oauth2, GmailOAuth2Delivery::DeliveryMethod
