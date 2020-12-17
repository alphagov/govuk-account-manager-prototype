class ApplicationKey < ApplicationRecord
  self.primary_keys = :application_uid, :key_id

  def to_key
    OpenSSL::PKey::EC.new(pem)
  end
end
