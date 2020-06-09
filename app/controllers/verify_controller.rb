require "base64"

class VerifyController < ApplicationController
  def show
    bits = Base64.urlsafe_decode64(params[:token]).split("\0")
    if bits.count != 2
      @state = "malformed token"
    else
      user_id = bits[0]
      magic_value = bits[1]
      user = Services.keycloak.users.get(user_id)
      if user
        expected_token = user.attributes["verification_token"].first
        expiration = user.attributes["verification_token_expires"].first.to_datetime
        if expected_token == magic_value
          if Time.zone.now < expiration
            Services.keycloak.users.update(user_id, KeycloakAdmin::UserRepresentation.from_hash({ "emailVerified" => true }))
            @state = "ok"
          else
            @state = "expired token: #{expiration} < #{Time.zone.now}"
          end
        else
          @state = "bad verification token: expected #{expected_token}"
        end
      else
        @state = "no such user"
      end
    end
  end
end
