require "keycloak_client_extras"

module Services
  def self.keycloak
    @keycloak ||= KeycloakAdmin.realm(ENV["KEYCLOAK_REALM_ID"])
  end
end
