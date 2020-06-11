# frozen_string_literal: true

require "services"
require "email_confirmation"

class ApplicationController < ActionController::Base
  def authenticate_user!
    if session[:sub]
      @user = Services.keycloak.users.get(session[:sub])
    else
      do_authenticate_user
    end
  end

private

  def do_authenticate_user
    session[:nonce] = SecureRandom.hex(16)
    redirect_to Services.oidc.auth_uri(session[:nonce])
  end
end
