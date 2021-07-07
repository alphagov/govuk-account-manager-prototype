class LoginState < ApplicationRecord
  belongs_to :user

  EXPIRATION_AGE = 60.minutes
  scope :expired, -> { where("created_at < ?", EXPIRATION_AGE.ago) }
end
