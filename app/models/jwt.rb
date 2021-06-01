class Jwt < ApplicationRecord
  attr_accessor :skip_parse_jwt_token, :application_id_from_token

  has_one :registration_state, dependent: :destroy
  has_one :login_state, dependent: :destroy

  EXPIRATION_AGE = 60.minutes
  scope :expired, (lambda do
    left_joins(:login_state).where("login_states.jwt_id IS NULL")
      .left_joins(:registration_state).where("registration_states.jwt_id IS NULL")
      .where("jwts.created_at < ?", EXPIRATION_AGE.ago)
  end)

  before_save :parse_jwt_token, unless: :skip_parse_jwt_token

  class Nil
    def id; end

    def jwt_payload
      {}
    end

    def destroy_stale_states; end
  end

  class InvalidJWT < StandardError; end

  class MissingApplicationId < InvalidJWT; end

  class ApplicationNotFound < InvalidJWT; end

  class InsufficientScopes < InvalidJWT; end

  class InvalidOAuthRedirect < InvalidJWT; end

  class JWTDecodeError < InvalidJWT; end

  def destroy_stale_states
    transaction do
      RegistrationState.where(jwt_id: id).tap do |states|
        states.update_all(jwt_id: nil)
        states.destroy_all
      end

      LoginState.where(jwt_id: id).tap do |states|
        states.update_all(jwt_id: nil)
        states.destroy_all
      end
    end
  end

private

  def parse_jwt_token
    raise MissingApplicationId unless application_id_from_token

    begin
      application = Doorkeeper::Application.find(application_id_from_token)
    rescue ActiveRecord::RecordNotFound
      raise ApplicationNotFound
    end

    payload, = JWT.decode jwt_payload, nil, false
    scopes = application.scopes.to_a.map(&:to_sym)

    attributes = payload.fetch("attributes", {}).transform_keys(&:to_sym)
    attributes.each_key do |attribute|
      allowed_write_scopes = ScopeDefinition.new.jwt_attributes_and_scopes.fetch(attribute, [])
      raise InsufficientScopes unless scopes.any? { |scope| allowed_write_scopes.include? scope }
    end

    post_register_oauth = payload["post_register_oauth"]&.delete_prefix(Rails.application.config.redirect_base_url)
    if post_register_oauth
      raise InvalidOAuthRedirect unless post_register_oauth.starts_with? "/oauth/authorize"
    end

    self.jwt_payload = {
      application: application,
      scopes: scopes,
      attributes: attributes,
      post_register_oauth: post_register_oauth,
    }
  rescue JWT::DecodeError
    raise JWTDecodeError
  end
end
