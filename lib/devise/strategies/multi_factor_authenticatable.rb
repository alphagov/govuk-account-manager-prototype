require "devise/strategies/authenticatable"

module Devise
  module Strategies
    class MultiFactorAuthenticatable < Authenticatable
      def authenticate!
        resource = mapping.to.find_for_database_authentication(authentication_hash)
        hashed = false

        if resource && !active_for_authentication?(resource)
          paranoid_fail resource.inactive_message
          return
        end

        if validate(resource) { hashed = true; resource.valid_password?(password) } # rubocop:disable Style/Semicolon
          if resource.needs_mfa?
            env["warden.mfa.bypass"] = MultiFactorAuth.verify_bypass_token(resource, env["warden.mfa.bypass_token"])
            env["warden.mfa.required"] = !env["warden.mfa.bypass"]
          else
            env["warden.mfa.required"] = false
          end

          if env["warden.mfa.required"]
            env["devise.skip_trackable"] = true
            env["warden"].set_user(resource, store: false)
          else
            remember_me(resource)
            resource.after_database_authentication
            success!(resource)
          end
        end

        paranoid_fail :not_found_in_database unless resource
      end

      def active_for_authentication?(resource)
        !resource.respond_to?(:active_for_authentication?) || resource.active_for_authentication?
      end

      def paranoid_fail(error)
        fail(Devise.paranoid ? :invalid : error) # rubocop:disable Style/SignalException
      end
    end
  end
end
