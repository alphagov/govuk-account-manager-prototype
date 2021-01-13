module MultiFactorAuth
  ALLOWED_ATTEMPTS = 6
  EXPIRATION_AGE = 30.minutes
  INTERNATIONAL_CODE_REGEX = /^00/.freeze
  VALID_DOMESTIC_COUNTRIES = %i[gb gg je im].freeze

  class MFAError < StandardError; end
  class Disabled < MFAError; end
  class NotConfigured < MFAError; end

  def self.valid?(phone_number)
    return false unless phone_number

    parsed_number = TelephoneNumber.parse(phone_number.gsub(INTERNATIONAL_CODE_REGEX, "+"))

    if domestic_country_code(phone_number)
      true
    elsif parsed_number.country && parsed_number.valid? && parsed_number.valid_types.include?(:mobile)
      true
    else
      false
    end
  end

  def self.e164_number(phone_number)
    return unless valid? phone_number

    if (country_code = domestic_country_code(phone_number))
      TelephoneNumber.parse(phone_number, country_code).e164_number
    else
      TelephoneNumber.parse(phone_number.gsub(INTERNATIONAL_CODE_REGEX, "+")).e164_number
    end
  end

  def self.formatted_phone_number(phone_number)
    parsed_number = TelephoneNumber.parse(phone_number)

    if parsed_number.country && parsed_number.country.country_id == "GB"
      parsed_number.national_number
    else
      parsed_number.international_number
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
      :too_many_attempts
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

  def self.domestic_country_code(phone_number)
    VALID_DOMESTIC_COUNTRIES.each do |country_code|
      return country_code if TelephoneNumber.valid?(phone_number, country_code, [:mobile])
    end
    false
  end
end
