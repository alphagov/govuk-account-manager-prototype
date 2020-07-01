require "keycloak_client_extras"

module Services
  def self.keycloak
    @keycloak ||= KeycloakAdmin.realm(ENV["KEYCLOAK_REALM_ID"])
  end

  def self.discover
    @discover ||= OpenIDConnect::Discovery::Provider::Config.discover! "#{ENV['KEYCLOAK_SERVER_URL']}/realms/#{ENV['KEYCLOAK_REALM_ID']}"
  end

  def self.oauth2
    @oauth2 ||= Rack::OAuth2::Client.new(
      identifier: ENV["KEYCLOAK_CLIENT_ID"],
      secret: Rails.application.secrets.keycloak_client_secret,
      redirect_uri: "#{Rails.application.config.redirect_base_url}/auth/keycloak/callback",
      authorization_endpoint: discover.authorization_endpoint,
      token_endpoint: discover.token_endpoint,
    )
  end
end
