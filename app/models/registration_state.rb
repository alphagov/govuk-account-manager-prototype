class RegistrationState < ApplicationRecord
  enum state: {
    start: 0,
    your_information: 1,
    transition_emails: 2,
    finish: 3,
  }
end
