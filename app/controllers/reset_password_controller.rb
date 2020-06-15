require "reset_password"

class ResetPasswordController < ApplicationController
  def show; end

  def submit
    @email = reset_password_params[:email]
    user = Services.keycloak.users.search(@email)
    if user.empty?
      @state = :no_such_user
    else
      ResetPassword.send(user.first)
      user = Services.keycloak.users.search(@email)
      @user = user.first
      @state = :ok
    end
  end

private

  def reset_password_params
    params.permit(:email)
  end
end
