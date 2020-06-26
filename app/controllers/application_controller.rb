# frozen_string_literal: true

require "email_confirmation"

class ApplicationController < ActionController::Base
  if ENV["REQUIRE_BASIC_AUTH"]
    http_basic_authenticate_with(
      name: ENV.fetch("BASIC_AUTH_USERNAME"),
      password: ENV.fetch("BASIC_AUTH_PASSWORD"),
    )
  end

  def authenticate_user!
    @user = Services.keycloak.users.get(session[:sub]) if session[:sub]
    redirect_to "/auth/keycloak?return_to=#{request.path}" unless @user
  end
end
