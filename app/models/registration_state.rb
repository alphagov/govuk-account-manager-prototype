class RegistrationState < ApplicationRecord
  enum state: {
    start: 0,
    phone: 1,
    your_information: 2,
    transition_emails: 3,
    finish: 4,
  }

  belongs_to :jwt, optional: true, dependent: :destroy
  delegate :jwt_payload, to: :jwt, allow_nil: true
end
