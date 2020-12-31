require "rest-client"

class BannedPassword < ApplicationRecord
  NCSC_DENYLIST_URL = "https://ncsc.gov.uk/static-assets/documents/PwnedPasswordsTop100k.txt".freeze

  def self.import_from_ncsc
    response = RestClient.get NCSC_DENYLIST_URL
    _header, passwords = response.body.lines.map(&:rstrip).to_a.split("--")
    import_list(passwords)
  end

  def self.import_list(denylist)
    denylist = denylist.select { |password| Devise.password_length.include? password.length }.uniq

    transaction do
      delete_all
      insert_all(denylist.map { |password| { password: password.downcase } }, returning: %w[id]).count # pragma: allowlist secret
    end
  end

  def self.is_password_banned?(candidate)
    where(password: candidate.downcase).exists? # pragma: allowlist secret
  end
end
