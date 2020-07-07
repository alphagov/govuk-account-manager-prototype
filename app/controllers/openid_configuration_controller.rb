require "services"

class OpenidConfigurationController < ApplicationController
  def show
    modified_oidc_configuration = oidc_configuration.merge(
      authorization_endpoint: Rails.application.config.redirect_base_url + "/login",
      end_session_endpoint: Rails.application.config.redirect_base_url + "/logout",
    )

    render json: modified_oidc_configuration
  end

private

  def oidc_configuration
    response = HTTParty.get(Services.discover_endpoint + "/.well-known/openid-configuration", format: :plain)
    JSON.parse response, symbolize_names: true
  end
end
