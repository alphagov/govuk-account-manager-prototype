class ApplicationKey < ApplicationRecord
  class InvalidJWT < StandardError; end
  class InsufficientScopes < InvalidJWT; end
  class InvalidScopes < InvalidJWT; end
  class JWTDecodeError < InvalidJWT; end
  class KeyNotFound < InvalidJWT; end
  class MissingFieldKey < InvalidJWT; end
  class MissingFieldUid < InvalidJWT; end
  class MissingFieldPostLoginOAuth < InvalidJWT; end
  class UidNotFound < InvalidJWT; end
  class InvalidOAuthRedirect < InvalidJWT; end

  self.primary_keys = :application_uid, :key_id

  def self.find_key(application_uid:, key_id:)
    ApplicationKey.find([application_uid, key_id])
  end

  def self.validate_jwt!(token)
    payload, = JWT.decode token, nil, false
    raise MissingFieldUid unless payload["uid"]
    raise MissingFieldKey unless payload["key"]

    application = Doorkeeper::Application.by_uid(payload["uid"])
    raise UidNotFound unless application

    signing_key = find_key(application_uid: payload["uid"], key_id: payload["key"])
    payload, = JWT.decode token, signing_key.to_key, true, { algorithm: "ES256" }

    scopes = payload.fetch("scopes", []).map(&:to_sym)
    scopes.each do |scope|
      raise InvalidScopes unless application.includes_scope?(scope)
    end

    attributes = payload.fetch("attributes", {}).transform_keys(&:to_sym)
    attributes.each_key do |attribute|
      allowed_write_scopes = ScopeDefinition.new.jwt_attributes_and_scopes.fetch(attribute, [])
      raise InsufficientScopes unless scopes.any? { |scope| allowed_write_scopes.include? scope }
    end

    post_login_oauth = payload["post_login_oauth"]&.delete_prefix(Rails.application.config.redirect_base_url)
    raise MissingFieldPostLoginOAuth unless post_login_oauth
    raise InvalidOAuthRedirect unless post_login_oauth.starts_with? "/oauth/authorize"

    post_register_oauth = payload["post_register_oauth"]&.delete_prefix(Rails.application.config.redirect_base_url)
    if post_register_oauth
      raise InvalidOAuthRedirect unless post_register_oauth.starts_with? "/oauth/authorize"
    end

    {
      application: application,
      signing_key: signing_key,
      scopes: scopes,
      attributes: attributes,
      post_login_oauth: post_login_oauth,
      post_register_oauth: post_register_oauth,
    }
  rescue JWT::DecodeError
    raise JWTDecodeError
  rescue ActiveRecord::RecordNotFound
    raise KeyNotFound
  end

  def application
    Doorkeeper::Application.by_uid(application_uid)
  end

  def to_key
    OpenSSL::PKey::EC.new(pem)
  end
end
