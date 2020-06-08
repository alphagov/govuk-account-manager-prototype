require "oidc_client"
require "keycloak_client_extras"

module Services
  def self.keycloak
    @keycloak ||= KeycloakAdmin.realm(ENV["KEYCLOAK_REALM_ID"])
  end

  def self.oidc
    @oidc ||= OIDCClient.new(
      "#{ENV['KEYCLOAK_SERVER_URL']}/realms/#{ENV['KEYCLOAK_REALM_ID']}",
      ENV["KEYCLOAK_CLIENT_ID"],
      ENV["KEYCLOAK_CLIENT_SECRET"],
      "#{ENV['REDIRECT_BASE_URL']}/callback",
    )
  end
end
