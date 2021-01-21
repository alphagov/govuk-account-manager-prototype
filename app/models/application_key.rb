class ApplicationKey < ApplicationRecord
  def to_key
    OpenSSL::PKey::EC.new(pem)
  end
end
