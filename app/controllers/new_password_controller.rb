require "reset_password"

class NewPasswordController < ApplicationController
  def show
    @state = verify_user_token
  end

private

  def verify_user_token
    if params[:user_id] && params[:token]
      user = Services.keycloak.users.get(params[:user_id])
      ResetPassword.check_and_verify(user, params[:token])
    end
  end
end
