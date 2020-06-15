class RegisterController < ApplicationController
  rescue_from RestClient::Conflict, with: :conflict

  def show; end

  def create
    @email = params[:email]
    user = Services.keycloak.users.create!(
      @email,
      @email,
      params[:password],
      false,
      "en",
    )

    EmailConfirmation.send(user)
  end

private

  def conflict
    @email = params[:email]
    render action: "conflict", status: :conflict
  end
end
