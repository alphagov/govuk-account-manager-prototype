class RegisterController < ApplicationController
  include PasswordHelper
  rescue_from RestClient::Conflict, with: :conflict

  def show
    @email = register_params[:email]
  end

  def create
    if request_errors.empty?
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
      flash[:validation] = request_errors

      redirect_to action: :show, params: register_params
    end
  end

private

  def request_errors
    errors = []

    if register_params[:email].blank?
      errors << {
        field: "email",
        text: t("register.create.error.email_missing"),
      }
    end

    password_state = password_valid?(register_params[:password], register_params[:password_confirm])

    password_state.each do |password_validation|
      errors << {
        field: password_validation.match(/password_confirm/) ? "password_confirm" : "password",
        text: t("register.create.error.#{password_validation}"),
      }
    end

    errors
  end

  def register_params
    params.permit(:email, :password, :password_confirm)
  end

  def conflict
    @email = params[:email]
    render action: "conflict", status: :conflict
  end
end
