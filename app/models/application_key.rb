class ApplicationKey < ApplicationRecord
  self.primary_keys = :application_uid, :key_id

  def self.find_key(application_uid:, key_id:)
    ApplicationKey.find([application_uid, key_id])
  end

  def application
    Doorkeeper::Application.by_uid(application_uid)
  end

  def to_key
    OpenSSL::PKey::EC.new(pem)
  end
end
