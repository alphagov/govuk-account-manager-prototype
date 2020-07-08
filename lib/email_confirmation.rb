module EmailConfirmation
  def self.send(user)
    return false unless user&.email

    token = SecureRandom.hex(16)
    rep = { "attributes" => { "verification_token" => token, "verification_token_expires" => Time.zone.now + 24.hours } }
    # TODO: set attributes on user

    mailer = AccountMailer.with(link: link(user.id, token))
    mailer.confirmation_email(user.email).deliver_later

    true
  end

  def self.change_and_send(user, email)
    return false unless user&.email
    return false unless email

    token = SecureRandom.hex(16)
    rep = {
      "attributes" => {
        "new_email_address" => email,
        "verification_token" => token,
        "verification_token_expires" => Time.zone.now + 24.hours,
      },
    }
    # TODO: set attributes on user

    AccountMailer.with(
      new_address: email,
      link: cancel_link(user.id),
    ).change_cancel_email(user.email, email).deliver_later

    AccountMailer.with(
      link: link(user.id, token),
    ).change_confirmation_email(email).deliver_later

    true
  end

  def self.check_and_verify(user, token)
    expected = user&.attributes&.fetch("verification_token", nil)&.first
    expires = user&.attributes&.fetch("verification_token_expires", nil)&.first&.to_datetime
    new_email_address = user&.attributes&.fetch("new_email_address", nil)&.first

    return :no_such_user unless user && expected && expires
    return :token_mismatch unless expected == token
    return :token_expired unless Time.zone.now < expires

    rep = {
      "emailVerified" => true,
      "attributes" => {
        "new_email_address" => nil,
        "verification_token" => nil,
        "verification_token_expires" => nil,
      },
    }
    rep["email"] = new_email_address if new_email_address

    # throws RestClient::Conflict if the new address is in use
    # TODO: set attributes on user
    :ok
  end

  def self.cancel_change(user)
    expected = user&.attributes&.fetch("new_email_address", nil)&.first

    return :no_such_user unless user
    return :too_late unless expected

    rep = {
      "attributes" => {
        "new_email_address" => nil,
        "verification_token" => nil,
        "verification_token_expires" => nil,
      },
    }
    # TODO: set attributes on user

    :ok
  end

  def self.link(user_id, token)
    base_url = Rails.application.config.redirect_base_url
    base_url += "/" unless base_url.end_with? "/"

    "#{base_url}confirm-email?user_id=#{user_id}&token=#{token}"
  end

  def self.cancel_link(user_id)
    base_url = Rails.application.config.redirect_base_url
    base_url += "/" unless base_url.end_with? "/"

    "#{base_url}confirm-email/cancel-change?user_id=#{user_id}"
  end
end
