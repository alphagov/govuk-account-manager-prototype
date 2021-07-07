class RegistrationState < ApplicationRecord
  enum state: {
    start: 0,
    phone: 1,
    your_information: 2,
    finish: 4,
  }

  EXPIRATION_AGE = 60.minutes
  scope :expired, -> { where("created_at < ?", EXPIRATION_AGE.ago) }

  before_save :format_phone_number

  def format_phone_number
    self.phone = MultiFactorAuth.e164_number(phone) if phone
  end
end
