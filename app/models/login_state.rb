class LoginState < ApplicationRecord
  belongs_to :user
  belongs_to :jwt, optional: true, dependent: :destroy

  EXPIRATION_AGE = 60.minutes
  scope :expired, -> { where("created_at < ?", EXPIRATION_AGE.ago) }
end
