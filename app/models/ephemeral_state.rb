class EphemeralState < ApplicationRecord
  belongs_to :user

  def to_hash
    {
      _ga: ga_client_id,
      cookie_consent: user.cookie_consent,
    }.compact
  end
end
