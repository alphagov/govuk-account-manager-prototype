class MfaToken < ApplicationRecord
  belongs_to :user

  paginates_per 10

  def self.generate!(user)
    create!(
      user: user,
      token: SecureRandom.hex(64),
    )
  end

  def valid_until
    created_at + MultiFactorAuth::BYPASS_TOKEN_EXPIRATION_AGE
  end
end
