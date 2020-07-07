require "services"

class ApplicationController < ActionController::Base
  if ENV["REQUIRE_BASIC_AUTH"]
    http_basic_authenticate_with(
      name: ENV.fetch("BASIC_AUTH_USERNAME"),
      password: ENV.fetch("BASIC_AUTH_PASSWORD"),
    )
  end

  def authenticate_user!
    refresh_access_token! if session[:refresh_token]
    @user = Services.keycloak.users.get(session[:sub]) if session[:sub]
    redirect_to "/auth/oidc?return_to=#{request.path}" unless @user && @access_token
  end

  def refresh_access_token!
    Services.oauth2.refresh_token = session[:refresh_token]
    if (resp = Services.oauth2.access_token!)
      @access_token = resp.access_token
      session[:refresh_token] = resp.refresh_token
    end
  rescue Rack::OAuth2::Client::Error # rubocop:disable Lint/SuppressedException
  end
end
