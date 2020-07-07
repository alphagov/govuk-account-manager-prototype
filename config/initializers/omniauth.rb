require_relative "../../lib/omniauth/govuk_oidc"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :govuk_oidc, {
    name: :oidc,
    client_id: ENV["KEYCLOAK_CLIENT_ID"],
    client_secret: Rails.application.secrets.keycloak_client_secret,
    redirect_uri: "#{ENV['REDIRECT_BASE_URL']}/auth/keycloak/callback",
    return_to_prefix: "/account",
    return_to_default: "/account",
  }
end
