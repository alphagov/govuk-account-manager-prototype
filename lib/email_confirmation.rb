require "services"

module EmailConfirmation
  def self.send(user)
    return false unless user.email

    token = SecureRandom.hex(16)
    rep = { "attributes" => { "verification_token" => token, "verification_token_expires" => Time.zone.now + 24.hours } }
    Services.keycloak.users.update(user.id, KeycloakAdmin::UserRepresentation.from_hash(rep))

    mailer = AccountMailer.with(link: link(user.id, token))
    mailer.confirmation_email(user.email).deliver_later

    true
  end

  def self.check_and_verify(user, token)
    expected = user&.attributes&.fetch("verification_token")&.first
    expires = user&.attributes&.fetch("verification_token_expires")&.first&.to_datetime

    return :no_such_user unless user && expected && expires
    return :token_mismatch unless expected == token
    return :token_expired unless Time.zone.now < expires

    rep = {
      "emailVerified" => true,
      "attributes" => { "verification_token" => nil, "verification_token_expires" => nil },
    }
    Services.keycloak.users.update(user.id, KeycloakAdmin::UserRepresentation.from_hash(rep))

    :ok
  end

  def self.link(user_id, token)
    base_url = Rails.application.config.redirect_base_url
    base_url += "/" unless base_url.end_with? "/"

    "#{base_url}confirm-email?user_id=#{user_id}&token=#{token}"
  end
end
