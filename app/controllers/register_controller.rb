require "base64"

class RegisterController < ApplicationController
  # bad!
  skip_before_action :verify_authenticity_token

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
    magic_value = SecureRandom.hex(64)
    rep = { "attributes" => { "verification_token" => magic_value, "verification_token_expires" => Time.zone.now + 24.hours } }
    Services.keycloak.users.update(user.id, KeycloakAdmin::UserRepresentation.from_hash(rep))
    @token = Base64.urlsafe_encode64("#{user.id}\0#{magic_value}")
  end

  def conflict
    render status: :conflict, plain: "409 error: user exists"
  end
end
