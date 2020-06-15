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

  def self.check_and_verify(user_id, token)
    return :bad_parameters unless user_id && token

    user = Services.keycloak.users.get(user_id)

    expected = user&.attributes&.fetch("reset_password_verification_token")&.first
    expires = user&.attributes&.fetch("reset_password_verification_token_expires")&.first&.to_datetime

    return :no_such_user unless user && expected && expires
    return :token_mismatch unless expected == token
    return :token_expired unless Time.zone.now < expires

    :ok
  end

  def self.update_password(user, password)
    Services.keycloak.users.update_password(user.id, password)

    rep = {
      "attributes" => { "reset_password_verification_token" => nil, "reset_password_verification_token_expires" => nil },
    }
    Services.keycloak.users.update(user.id, KeycloakAdmin::UserRepresentation.from_hash(rep))

    :ok
  end

  def self.link(user_id, token)
    base_url = ENV.fetch("REDIRECT_BASE_URL", "/")
    base_url += "/" unless base_url.end_with? "/"

    "#{base_url}new-password?user_id=#{user_id}&token=#{token}"
  end
end
