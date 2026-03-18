class TestMailMailer < ApplicationMailer
  def test_email(to:, subject:, body:)
    @body = body
    mail(
      to: to,
      subject: subject
    )
  end
end
