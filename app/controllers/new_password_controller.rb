require "reset_password"

class NewPasswordController < ApplicationController
  include PasswordHelper

  def show
    @user_id = new_password_params[:user_id]
    @token = new_password_params[:token]
    @state = ResetPassword.check_and_verify(@user_id, @token)
  end

  def submit
    @state = ResetPassword.check_and_verify(new_password_params[:user_id], new_password_params[:token])

    return unless @state == :ok

    user = Services.keycloak.users.get(new_password_params[:user_id])

    password_validity = password_valid?(new_password_params[:password], new_password_params[:password_confirm])

    if password_validity.empty?
      ResetPassword.update_password(user, new_password_params[:password])
    else
      flash[:validation] = password_validity.map do |error|
        {
          field: error.match(/password_confirm/) ? "password_confirm" : "password",
          text: t("new_password.error.#{error}"),
        }
      end

      redirect_to action: :show, user_id: new_password_params[:user_id], token: new_password_params[:token]
    end
  end

private

  def new_password_params
    params.permit(:user_id, :token, :password, :password_confirm)
  end
end
