# frozen_string_literal: true

require "services"

class ApplicationController < ActionController::Base
  # this isn't so great because it fires off an OIDC request for every
  # page view.  But I couldn't get the redis session store working,
  # and there's too much data to stick in a cookie; so this works as a
  # proof of concept.
  def authenticate_user!
    if params[:code] && session[:nonce]
      result = Services.oidc.handle_redirect(params[:code], session[:nonce])
      @access_token = result[:access_token]
      @id_token = result[:id_token]
      @user_info = @access_token.userinfo!
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
