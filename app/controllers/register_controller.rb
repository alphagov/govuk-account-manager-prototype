class RegisterController < ApplicationController
  # bad!
  skip_before_action :verify_authenticity_token

  rescue_from RestClient::Conflict, with: :conflict

  def show; end

  def create
    @email = params[:email]
    user = Services.keycloak.users.create!(
      @email,
      @email,
      params[:password],
      false,
      "en",
    )

    token = SecureRandom.hex(16)
    rep = { "attributes" => { "verification_token" => token, "verification_token_expires" => Time.zone.now + 24.hours } }
    Services.keycloak.users.update(user.id, KeycloakAdmin::UserRepresentation.from_hash(rep))

    send_confirmation_email(user.id, token)
  end

private

  def conflict
    render status: :conflict, plain: "409 error: user exists"
  end

  def send_confirmation_email(user_id, token)
    mailer = AccountMailer.with(
      link: "#{ENV['REDIRECT_BASE_URL']}/verify?user_id=#{user_id}&token=#{token}",
    )
    mailer.confirmation_email(@email).deliver_later
  end
end
