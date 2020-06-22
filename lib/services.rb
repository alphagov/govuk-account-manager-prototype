require "oidc_client"
require "keycloak_client_extras"

module Services
  def self.keycloak
    @keycloak ||= KeycloakAdmin.realm(ENV["KEYCLOAK_REALM_ID"])
  end

  def self.oidc
    @oidc ||=
      begin
        base_url = Rails.application.config.redirect_base_url
        base_url += "/" unless base_url.end_with? "/"
        OIDCClient.new(
          "#{ENV['KEYCLOAK_SERVER_URL']}/realms/#{ENV['KEYCLOAK_REALM_ID']}",
          ENV["KEYCLOAK_CLIENT_ID"],
          ENV["KEYCLOAK_CLIENT_SECRET"],
          "#{base_url}callback",
        )
      end
  end
end
