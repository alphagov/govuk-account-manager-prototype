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

    password_validity = password_valid?(params[:password], params[:password_confirm])

    if password_validity == :ok
      ResetPassword.update_password(user, params[:password])
    else
      flash[:validation] = [{
        field: "password",
        text: t("new_password.error.#{password_validity}"),
      }]

      redirect_to action: :show, user_id: params[:user_id], token: params[:token]
    end
  end

private

  def password_valid?(password, password_confirm)
    return :password_missing if password.blank?

    return :password_confirm_missing if password_confirm.blank?

    return :password_mismatch unless password == password_confirm

    :ok
  end
end
