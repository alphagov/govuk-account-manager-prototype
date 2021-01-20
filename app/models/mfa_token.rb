class MfaToken < ApplicationRecord
  belongs_to :user

  def self.generate!(user)
    create!(
      user: user,
      token: SecureRandom.hex(64),
    )
  end
end
