module RegistrationStateMachine
  def self.call(params, jwt_payload)
    password_errors = check_password(params)
    consent_errors = check_consent(params)
    email_decision_errors = check_email_decision(params, jwt_payload)

    if password_errors
      {
        state: :needs_password,
        resource_error_messages: password_errors,
      }
    elsif consent_errors
      {
        state: :needs_consent,
        resource_error_messages: consent_errors,
      }
    elsif email_decision_errors
      {
        state: :needs_email_decision,
        resource_error_messages: email_decision_errors,
      }
    else
      {
        state: :finish,
        resource_error_messages: nil,
      }
    end
  end

  def self.check_password(params)
    password = params.dig(:user, :password) # pragma: allowlist secret
    password_confirmation = params.dig(:user, :password_confirmation)
    return {} unless password

    password_format_ok = User::PASSWORD_REGEX.match? password
    password_length_ok = Devise.password_length.include? password.length
    password_confirmation_ok = password == password_confirmation
    unless password_format_ok && password_length_ok && password_confirmation_ok
      {
        password: [ # pragma: allowlist secret
          password_format_ok ? nil : I18n.t("activerecord.errors.models.user.attributes.password.invalid"),
          password_length_ok ? nil : I18n.t("activerecord.errors.models.user.attributes.password.too_short"),
        ],
        password_confirmation: [
          password_confirmation_ok ? nil : I18n.t("activerecord.errors.models.user.attributes.password_confirmation.confirmation"),
        ],
      }
    end
  end

  def self.check_consent(params)
    button = params.dig(:button, :needs_consent)
    button ? nil : {}
  end

  def self.check_email_decision(params, jwt_payload)
    email_topic_slug = (jwt_payload || {}).dig(:attributes, :transition_checker_state, "email_topic_slug")
    if email_topic_slug
      email_decision = params.dig(:email_decision)
      return {} unless email_decision

      email_decision_format_ok = %w[yes no].include? email_decision
      unless email_decision_format_ok
        {
          email_decision: [
            I18n.t("activerecord.errors.models.user.attributes.email_decision.invalid"),
          ],
        }
      end
    end
  end
end
