class VerifyController < ApplicationController
  # we probably want to implement a way to re-request a link in these
  # failure cases
  def show
    user_id = params[:user_id]
    token = params[:token]

    if user_id.nil? || token.nil?
      @state = "Invalid link"
      return
    end

    user = Services.keycloak.users.get(user_id)
    expected = user&.attributes&.fetch("verification_token")&.first
    expires = user&.attributes&.fetch("verification_token_expires")&.first&.to_datetime

    if user && expected && expires
      unless expected == token
        @state = "Invalid link"
        return
      end

      unless Time.zone.now < expires
        @state = "Link has expired"
        return
      end

      Services.keycloak.users.update(user_id, KeycloakAdmin::UserRepresentation.from_hash({ "emailVerified" => true }))
      @state = "Your email address has been confirmed"
    else
      @message = "User not found"
    end
  end
end
