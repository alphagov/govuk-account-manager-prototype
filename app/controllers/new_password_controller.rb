require "reset_password"

class NewPasswordController < ApplicationController
  def show
    @user_id = params[:user_id]
    @token = params[:token]
    @state = ResetPassword.check_and_verify(@user_id, @token)
  end

  def submit
    @state = ResetPassword.check_and_verify(params[:user_id], params[:token])

    return unless @state == :ok

    user = Services.keycloak.users.get(params[:user_id])

    if password_valid?(params[:password])
      ResetPassword.update_password(user, params[:password])
    else
      flash.now[:validation] = [{
        field: "password",
        text: t("new_password.password_invalid"),
      }]
      render "show"
    end
  end

private

  def password_valid?(password)
    password.present?
  end
end
