require "reset_password"

class ResetPasswordController < ApplicationController
  def show
    @email = reset_password_params[:email]
  end

  def submit
    @email = reset_password_params[:email]
    user = nil # TODO: implement
    unless ResetPassword.send(user)
      flash[:validation] = [{
        field: "email",
        text: t("reset_password.no_such_user"),
      }]

      redirect_to action: :show, params: reset_password_params
    end
  end

private

  def reset_password_params
    params.permit(:email)
  end
end
