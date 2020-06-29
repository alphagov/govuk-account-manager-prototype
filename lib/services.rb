require "keycloak_client_extras"

module Services
  def self.keycloak
    @keycloak ||= KeycloakAdmin.realm(ENV["KEYCLOAK_REALM_ID"])
  end

  def self.discover
    @discover ||= OpenIDConnect::Discovery::Provider::Config.discover! "#{ENV['KEYCLOAK_SERVER_URL']}/realms/#{ENV['KEYCLOAK_REALM_ID']}"
  end
end
