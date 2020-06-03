class RegisterController < ApplicationController
  # bad!
  skip_before_action :verify_authenticity_token

  rescue_from RestClient::Conflict, with: :conflict

  def index; end

  def create
    @email = params[:email]
    KeycloakAdmin.realm(ENV["KEYCLOAK_REALM_ID"]).users.create!(
      @email,
      @email,
      params[:password],
      false,
      "en",
    )
  end

  def conflict
    render status: :conflict, plain: "409 error: user exists"
  end
end
