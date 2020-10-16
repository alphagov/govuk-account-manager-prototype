module MultiFactorAuth
  def self.send_phone_mfa(phone_number, digits: 6)
    phone_code = (1..digits).map { |_| SecureRandom.random_number(10).to_s }.join("")
    NotifySmsDeliveryJob.perform_later(
      phone_number,
      "Your two-factor authentication code is #{phone_code}",
    )
    phone_code
  end

  def self.is_enabled
    Rails.configuration.feature_flag_mfa
  end
end
