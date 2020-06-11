require "services"

module ResetPassword
  def self.send(user)
    return false unless user.email

    token = SecureRandom.hex(16)
    rep = { "attributes" => { "reset_password_verification_token" => token, "reset_password_verification_token_expires" => Time.zone.now + 24.hours } }
    Services.keycloak.users.update(user.id, KeycloakAdmin::UserRepresentation.from_hash(rep))

    mailer = AccountMailer.with(link: link(user.id, token))
    mailer.reset_password_email(user.email).deliver_later

    true
  end

  def self.link(user_id, token)
    base_url = ENV.fetch("REDIRECT_BASE_URL", "/")
    base_url += "/" unless base_url.end_with? "/"

    "#{base_url}reset-password?user_id=#{user_id}&token=#{token}"
  end
end
