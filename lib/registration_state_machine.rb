module RegistrationStateMachine
  def self.call(params, jwt_payload)
    state = nil
    resource_error_messages = nil

    password = params.dig(:user, :password) # pragma: allowlist secret
    password_confirmation = params.dig(:user, :password_confirmation)
    if password
      password_format_ok = User::PASSWORD_REGEX.match? password
      password_length_ok = Devise.password_length.include? password.length
      password_confirmation_ok = password == password_confirmation

      if password_format_ok && password_length_ok && password_confirmation_ok
        email_topic_slug = (jwt_payload || {}).dig(:attributes, :transition_checker_state, "email_topic_slug")

        if email_topic_slug
          email_decision = params.dig(:email_decision)
          email_decision_format_ok = %w[yes no].include? email_decision

          if email_decision && email_decision_format_ok
            state = :finish
          else
            state = :needs_email_decision
            resource_error_messages = {
              email_decision: email_decision ? [I18n.t("activerecord.errors.models.user.attributes.email_decision.invalid")] : nil,
            }.compact
          end
        else
          state = :finish
        end
      else
        state = :needs_password
        resource_error_messages = {
          password: [ # pragma: allowlist secret
            password_format_ok ? nil : I18n.t("activerecord.errors.models.user.attributes.password.invalid"),
            password_length_ok ? nil : I18n.t("activerecord.errors.models.user.attributes.password.too_short"),
          ],
          password_confirmation: password_confirmation_ok ? nil : [I18n.t("activerecord.errors.models.user.attributes.password_confirmation.confirmation")],
        }.compact
      end
    else
      state = :needs_password
    end

    {
      state: state,
      resource_error_messages: resource_error_messages,
    }
  end
end
