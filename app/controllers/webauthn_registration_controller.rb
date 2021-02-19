class WebauthnRegistrationController < ApplicationController
  before_action :authenticate_user!
  before_action :create_webauthn_id, only: :create

  def show
    @registered_credentials = current_user.webauthn_credentials
  end

  def create
    options = generate_options

    session[:creation_challenge] = options.challenge

    respond_to do |format|
      format.json { render json: options }
    end
  end

  def callback
    credential_with_attestation = WebAuthn::Credential.from_create(params[:publicKeyCredential])

    begin
      credential_with_attestation.verify(session[:creation_challenge])
      credential = current_user.webauthn_credentials.build(
        external_id: Base64.urlsafe_encode64(credential_with_attestation.raw_id, padding: false),
        nickname: params[:credential_nickname] || generate_random_nickname,
        public_key: credential_with_attestation.public_key,
        sign_count: credential_with_attestation.sign_count,
      )

      if credential.save
        render json: { status: "ok" }, status: :ok
      else
        render json: "Couldn't register your Security Key", status: :unprocessable_entity
      end
    rescue WebAuthn::Error => e
      render json: "Verification failed: #{e.message}", status: :unprocessable_entity
    ensure
      session.delete("creation_challenge")
    end
  end

private

  def generate_options
    WebAuthn::Credential.options_for_create(
      user: { id: current_user.webauthn_id, name: current_user.email },
      exclude: current_user.webauthn_credentials.pluck(:external_id),
    )
  end

  def create_webauthn_id
    unless current_user.webauthn_id
      current_user.update!(webauthn_id: WebAuthn.generate_user_id)
    end
  end

  def generate_random_nickname
    letters = [("a".."z"), ("A".."Z")].map(&:to_a).flatten
    (0...10).map { letters[rand(letters.length)] }.join
  end
end
