class RegistrationState < ApplicationRecord
  enum state: {
    start: 0,
    phone: 1,
    your_information: 2,
    transition_emails: 3,
    finish: 4,
  }
end
