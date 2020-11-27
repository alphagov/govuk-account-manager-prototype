class DeviseSessionsController < Devise::SessionsController
  include ApplicationHelper
  include CookiesHelper

  before_action :check_login_state, only: %i[
    create
    phone_code
    phone_code_send
    phone_verify
    phone_resend
  ]

  def create
    render :new and return unless params.dig(:user, :password)

    self.resource = warden.authenticate(auth_options)
    if resource
      login_state.update!(password_ok: true)
      if request.env["warden.mfa.required"]
        MultiFactorAuth.generate_and_send_code(resource)
        redirect_to user_session_phone_code_path(login_state_id: @login_state_id)
      else
        do_sign_in
      end
    else
      @password_error_message =
        case User.find_by(email: params.dig(:user, :email))&.unauthenticated_message
        when :last_attempt
          I18n.t("devise.failure.last_attempt")
        when :locked
          I18n.t("devise.failure.locked")
        else
          I18n.t("devise.sessions.new.fields.password.errors.incorrect")
        end
      render :new
    end
  end

  def phone_code; end

  def phone_code_send
    MultiFactorAuth.generate_and_send_code(login_state.user)

    render :phone_code
  end

  def phone_verify
    state = MultiFactorAuth.verify_code(login_state.user, params[:phone_code])
    if state == :ok
      do_sign_in
      login_state.user.update!(last_mfa_success: Time.zone.now)
      login_state.destroy!
    else
      @phone_code_error_message = I18n.t("mfa.errors.phone_code.#{state}", resend_link: user_session_phone_resend_path(login_state_id: @login_state_id))
      render :phone_code
    end
  end

  def phone_resend; end

  def destroy
    redirect_to account_delete_confirmation_path and return if params[:done] == "delete"
    redirect_to transition_path and return if all_signed_out?

    if params[:continue]
      current_user.invalidate_all_sessions!
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
      redirect_to "#{transition_checker_path}/logout?done=#{params[:continue]}"
    elsif params[:done]
      current_user.invalidate_all_sessions!
      super
    else
      redirect_to "#{transition_checker_path}/logout?continue=1"
    end
  end

protected

  def verify_signed_out_user; end

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

  def do_sign_in
    cookies[:cookies_preferences_set] = "true"
    response["Set-Cookie"] = cookies_policy_header(login_state.user)

    sign_in(resource_name, login_state.user)
    redirect_to login_state.redirect_path
  end

  def after_sign_out_path_for(_resource)
    transition_path
  end
end
