require "reset_password"

class ResetPasswordController < ApplicationController
  def show
    @email = reset_password_params[:email]
  end

  def submit
    @email = reset_password_params[:email]
    user = Services.keycloak.users.search(@email)
    if user.empty?
      flash[:validation] = [{
        field: "email",
        text: t("reset_password.no_such_user"),
      }]

      redirect_to action: :show, params: reset_password_params
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
