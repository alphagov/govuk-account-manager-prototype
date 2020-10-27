class DevisePasswordsController < Devise::PasswordsController
  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource.email))
    else
      respond_with(resource)
    end
  end

  def sent
    @email = params&.dig(:email)
  end

protected

  # The path used after sending reset password instructions
  def after_sending_reset_password_instructions_path_for(resource_email)
    reset_password_sent_path(email: resource_email) if is_navigational_format?
  end
end
