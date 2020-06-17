class RegisterController < ApplicationController
  include PasswordHelper
  rescue_from RestClient::Conflict, with: :conflict

  def show
    @email = register_params[:email]
  end

  def create
    if request_state == :ok
      @email = register_params[:email]

      user = Services.keycloak.users.create!(
        @email,
        @email,
        params[:password],
        false,
        "en",
      )

      EmailConfirmation.send(user)
    else
      flash[:validation] = [{
        field: "password",
        text: t("register.create.error.#{request_state}"),
      }]

      redirect_to action: :show, params: register_params
    end
  end

private

  def request_state
    return :email_missing if register_params[:email].blank?

    password_valid?(register_params[:password], register_params[:password_confirm])
  end

  def register_params
    params.permit(:email, :password, :password_confirm)
  end

  def conflict
    @email = params[:email]
    render action: "conflict", status: :conflict
  end
end
