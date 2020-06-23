KeycloakAdmin.configure do |config|
  config.use_service_account = true
  config.server_url          = ENV["KEYCLOAK_SERVER_URL"]
  config.server_domain       = ENV["KEYCLOAK_SERVER_DOMAIN"]
  config.client_id           = ENV["KEYCLOAK_ADMIN_CLIENT_ID"]
  config.client_realm_name   = ENV["KEYCLOAK_REALM_ID"]
  config.client_id           = ENV["KEYCLOAK_CLIENT_ID"]
  config.client_secret       = ENV["KEYCLOAK_CLIENT_SECRET"]
  config.logger              = Rails.logger
  config.rest_client_options = { verify_ssl: OpenSSL::SSL::VERIFY_NONE }
end
