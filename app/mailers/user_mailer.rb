class UserMailer < ApplicationMailer
  def password_changed
    @user = params[:user]
    @changed_by = params[:changed_by]
    mail to: @user.email,
      subject: 'Your password has been changed'
  end
end
