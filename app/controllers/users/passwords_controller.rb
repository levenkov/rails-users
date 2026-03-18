# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  respond_to :html, :json

  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name)) do |format|
        format.json { render :create }
      end
    else
      respond_with(resource)
    end
  end
end
