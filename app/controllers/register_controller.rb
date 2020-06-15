class RegisterController < ApplicationController
  include PasswordHelper
  rescue_from RestClient::Conflict, with: :conflict

  def show; end

  def create
    @email = register_params[:email]

    password_validity = password_valid?(register_params[:password], register_params[:password_confirm])

    if password_validity == :ok
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
        text: t("register.create.error.#{password_validity}"),
      }]

      redirect_to action: :show
    end
  end

private

  def register_params
    params.permit(:email, :password, :password_confirm)
  end

  def conflict
    @email = params[:email]
    render action: "conflict", status: :conflict
  end
end
