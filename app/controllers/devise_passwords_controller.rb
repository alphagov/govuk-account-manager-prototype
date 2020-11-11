class DevisePasswordsController < Devise::PasswordsController
  # PUT /resource/password
  def update
    super do |resource|
      SecurityActivity.change_password!(resource, request.remote_ip) if resource.errors.empty?
    end
  end

  def sent
    @email = params&.dig(:email)
  end

protected

  # The path used after sending reset password instructions
  def after_sending_reset_password_instructions_path_for(_resource_name)
    reset_password_sent_path(email: resource.email) if is_navigational_format?
  end
end
