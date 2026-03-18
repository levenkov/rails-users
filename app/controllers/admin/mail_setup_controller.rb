class Admin::MailSetupController < Admin::BaseController
  def index
    @client_id = Rails.application.credentials.dig(:google, :mailer, :client_id)
    @client_secret = Rails.application.credentials.dig(:google, :mailer, :client_secret)
    @refresh_token = Rails.application.credentials.dig(:google, :mailer, :refresh_token)
    @from_email = Rails.application.credentials.dig(:google, :mailer, :from)
  end

  def authorize_google
    client_id = Rails.application.credentials.dig(:google, :mailer, :client_id)
    redirect_uri = callback_admin_mail_setup_index_url
    scope = 'https://mail.google.com/'

    auth_url = URI::HTTPS.build(
      host: 'accounts.google.com',
      path: '/o/oauth2/v2/auth',
      query: URI.encode_www_form(
        client_id: client_id,
        redirect_uri: redirect_uri,
        response_type: 'code',
        scope: scope,
        access_type: 'offline',
        prompt: 'consent'
      )
    ).to_s

    redirect_to auth_url, allow_other_host: true
  end

  def callback
    code = params[:code]

    if code
      client_id = Rails.application.credentials.dig(:google, :mailer, :client_id)
      client_secret = Rails.application.credentials.dig(:google, :mailer, :client_secret)
      redirect_uri = callback_admin_mail_setup_index_url

      uri = URI('https://oauth2.googleapis.com/token')
      res = Net::HTTP.post_form(uri,
        'client_id' => client_id,
        'client_secret' => client_secret,
        'code' => code,
        'grant_type' => 'authorization_code',
        'redirect_uri' => redirect_uri
      )

      if res.is_a?(Net::HTTPSuccess)
        body = JSON.parse(res.body)
        @access_token = body['access_token']
        @refresh_token = body['refresh_token']
      else
        @error = "Token exchange failed: #{res.code} #{res.body}"
      end
    else
      @error = 'No authorization code received'
    end
  end

  def send_test
    to_email = params[:to]
    subject = params[:subject]
    body = params[:body]

    begin
      TestMailMailer.test_email(to: to_email, subject: subject, body: body).deliver_now
      flash[:notice] = "Test email successfully sent to #{to_email}"
    rescue => e
      flash[:alert] = "Send error: #{e.message}"
    end

    redirect_to admin_mail_setup_index_path
  end
end
