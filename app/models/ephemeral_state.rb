class EphemeralState < ApplicationRecord
  belongs_to :user

  EXPIRATION_AGE = 60.minutes
  scope :expired, -> { where("created_at < ?", EXPIRATION_AGE.ago) }

  def to_hash
    {
      _ga: ga_client_id,
      cookie_consent: user.cookie_consent,
    }.compact
  end
end
