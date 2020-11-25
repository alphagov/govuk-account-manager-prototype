module MultiFactorAuth
  ALLOWED_ATTEMPTS = 6
  EXPIRATION_AGE = 10.minutes

  class MFAError < StandardError; end
  class Disabled < MFAError; end
  class NotConfigured < MFAError; end

  def self.valid?(phone_number)
    parsed_number = TelephoneNumber.parse(phone_number.gsub(/^00/, "+"))

    if TelephoneNumber.valid?(phone_number, :gb, [:mobile])
      true
    elsif parsed_number.country && parsed_number.valid? && parsed_number.valid_types.include?(:mobile)
      true
    else
      false
    end
  end

  def self.generate_and_send_code(auth, use_unconfirmed: false)
    phone = use_unconfirmed ? auth.unconfirmed_phone : auth.phone

    raise Disabled unless is_enabled?
    raise NotConfigured unless phone

    auth.update!(
      phone_code: send_phone_mfa(phone),
      phone_code_generated_at: Time.zone.now,
      mfa_attempts: 0,
    )
  end

  def self.verify_code(auth, candidate_phone_code)
    raise Disabled unless is_enabled?

    return :expired if auth.phone_code.nil?
    return :expired if auth.phone_code_generated_at < EXPIRATION_AGE.ago

    return :ok if candidate_phone_code == auth.phone_code

    if auth.mfa_attempts < MultiFactorAuth::ALLOWED_ATTEMPTS
      auth.update!(mfa_attempts: auth.mfa_attempts + 1)
      :invalid
    else
      auth.update!(phone_code: nil)
      :expired
    end
  end

  def self.send_phone_mfa(phone_number, digits: 5)
    raise Disabled unless is_enabled?

    phone_code = (1..digits).map { |_| SecureRandom.random_number(10).to_s }.join("")
    NotifySmsDeliveryJob.perform_later(
      phone_number,
      I18n.t("mfa.text_message.security_code.body", phone_code: phone_code),
    )
    phone_code
  end

  def self.is_enabled?
    Rails.configuration.feature_flag_mfa
  end
end
