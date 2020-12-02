require "devise/strategies/authenticatable"

module Devise
  module Strategies
    class MultiFactorAuthenticatable < Authenticatable
      def authenticate!
        resource = mapping.to.find_for_database_authentication(authentication_hash)
        hashed = false

        if validate(resource) { hashed = true; resource.valid_password?(password) } # rubocop:disable Style/Semicolon
          env["warden.mfa.required"] = MultiFactorAuth.is_enabled? && resource.needs_mfa?
          if env["warden.mfa.required"]
            env["devise.skip_trackable"] = true
            env["warden"].set_user(resource, store: false)
          else
            remember_me(resource)
            resource.after_database_authentication
            success!(resource)
          end
        end

        fail(Devise.paranoid ? :invalid : :not_found_in_database) unless resource # rubocop:disable Style/SignalException
      end
    end
  end
end
