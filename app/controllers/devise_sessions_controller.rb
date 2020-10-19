class DeviseSessionsController < Devise::SessionsController
  before_action :check_login_state, only: %i[
    phone_code
    phone_code_send
    phone_verify
    phone_resend
  ]

  def create
    payload = ApplicationKey.validate_jwt!(params[:jwt]) if params[:jwt]

    self.resource = warden.authenticate(auth_options)
    if resource
      redirect_path = payload ? payload[:post_login_oauth] : after_sign_in_path_for(resource)

      if request.env["warden.mfa.required"]
        initiate_mfa(resource, redirect_path)
      else
        do_sign_in(resource, redirect_path)
      end
    else
      @password_error_message = I18n.t("devise.sessions.new.fields.password.errors.incorrect")
      begin
        user = User.find_by!(email: params.dig(:user, :email))
        if user.locked_at?
          @password_error_message = I18n.t("devise.sessions.new.fields.password.errors.locked")
        end
      rescue ActiveRecord::RecordNotFound # rubocop:disable Lint/SuppressedException
      end
      render :new
    end
  end

  def phone_code; end

  def phone_code_send
    login_state.user.update!(
      phone_code: MultiFactorAuth.send_phone_mfa(login_state.user.phone),
      phone_code_generated_at: Time.zone.now,
      mfa_attempts: 0,
    )

    render :phone_code
  end

  def phone_verify
    if params[:phone_code] == login_state.user.phone_code && login_state.user.phone_code_generated_at >= MultiFactorAuth::EXPIRATION_AGE.ago
      do_sign_in(login_state.user, login_state.redirect_path)
      login_state.user.update!(last_mfa_success: Time.zone.now)
      login_state.destroy!
      return
    end

    if login_state.user.phone_code.nil? || login_state.user.phone_code_generated_at < MultiFactorAuth::EXPIRATION_AGE.ago
      @phone_code_error_message = I18n.t("devise.sessions.phone_code.errors.expired")
    elsif login_state.user.mfa_attempts < MultiFactorAuth::ALLOWED_ATTEMPTS
      login_state.user.update!(mfa_attempts: login_state.user.mfa_attempts + 1)
      @phone_code_error_message = I18n.t("devise.sessions.phone_code.errors.invalid")
    else
      login_state.user.update!(phone_code: nil)
      @phone_code_error_message = I18n.t("devise.sessions.phone_code.errors.expired")
    end
    render :phone_code
  end

  def phone_resend; end

protected

  def check_login_state
    @login_state_id = params[:login_state_id]
    redirect_to new_user_session_path unless login_state
  end

  def login_state
    @login_state ||=
      begin
        LoginState.find(@login_state_id)
      rescue ActiveRecord::RecordNotFound # rubocop:disable Lint/SuppressedException
      end
  end

  def initiate_mfa(resource, redirect_path)
    resource.update!(
      phone_code: MultiFactorAuth.send_phone_mfa(resource.phone),
      phone_code_generated_at: Time.zone.now,
      mfa_attempts: 0,
    )

    login_state = LoginState.create!(
      created_at: Time.zone.now,
      user_id: resource.id,
      redirect_path: redirect_path,
    )

    redirect_to user_session_phone_code_path(login_state_id: login_state.id)
  end

  def do_sign_in(resource, redirect_path)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    redirect_to redirect_path
  end

  def after_sign_in_path_for(_resource)
    target = params.fetch(:previous_url, user_root_path)
    if target.start_with?("/account") || target.start_with?("/oauth")
      target
    else
      user_root_path
    end
  end
end
