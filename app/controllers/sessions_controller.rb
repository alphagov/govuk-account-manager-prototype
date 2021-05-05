# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  include AcceptsJwt
  include ApplicationHelper
  include CookiesHelper
  include UrlHelper

  MFA_BYPASS_COOKIE_NAME = "_govuk_account_manager_prototype_remember_me"

  before_action :check_login_state, only: %i[
    phone_code
    phone_verify
    phone_resend
    phone_resend_code
  ]

  def create
    jwt = find_or_create_jwt

    render :new and return unless params.dig(:user, :email) || params.dig(:user, :password)

    @email = params.dig(:user, :email)
    catch(:warden) do
      request.env["warden.mfa.authenticate_to_level"] = params.dig(:authenticate_to_level)
      request.env["warden.mfa.bypass_token"] = (cookies.encrypted[MFA_BYPASS_COOKIE_NAME] || {})[@email]
      self.resource = warden.authenticate(auth_options)
    end

    if resource
      if resource.banned_password_match.nil?
        resource.update!(banned_password_match: BannedPassword.is_password_banned?(params.dig(:user, :password)))
      end

      LoginState.transaction do
        jwt.destroy_stale_states
        @login_state = LoginState.create!(
          created_at: Time.zone.now,
          user: resource,
          redirect_path: jwt.jwt_payload.dig("post_login_oauth").presence || params[:previous_url].presence,
          jwt_id: jwt.id,
        )
        @login_state_id = login_state.id
      end
      session[:login_state_id] = @login_state_id

      if request.env["warden.mfa.required"]
        MultiFactorAuth.generate_and_send_code(resource)
        redirect_to enter_phone_code_path
      elsif request.env["warden.mfa.bypass"]
        record_security_event(SecurityActivity::ADDITIONAL_FACTOR_BYPASS_USED, user: resource, analytics: analytics_data)
        do_sign_in(level_of_authentication: :level1, has_level1_but_skipped_mfa: true)
      else
        do_sign_in(level_of_authentication: :level0)
      end
    else
      @resource_error_messages = {}

      if params.dig(:user, :password).blank?
        @resource_error_messages[:password] = [I18n.t("activerecord.errors.models.user.attributes.password.blank")]
      end

      user = User.find_by(email: @email)
      user_exists = user.present?

      record_security_event(SecurityActivity::LOGIN_FAILURE, user: user, analytics: analytics_data) if user_exists

      if user_exists && !user.active_for_authentication? && !user.access_locked?
        @resource_error_messages[:email] = [I18n.t("devise.failure.unconfirmed")]
      elsif user_exists && params.dig(:user, :password).present?
        authentication_failure = user.unauthenticated_message
        @resource_error_messages[:password] = [I18n.t("devise.failure.#{authentication_failure}")]
      elsif user_exists
        @resource_error_messages[:password] = [I18n.t("activerecord.errors.models.user.attributes.password.blank")]
      elsif @email.present? && Devise.email_regexp.match?(@email)
        redirect_to new_user_registration_start_path(user: { email: @email }) and return if jwt.id

        render "registrations/transition_checker" and return if Rails.configuration.warn_about_transition_checker_when_logging_in_to_a_missing_account

        @resource_error_messages[:email] = [I18n.t("devise.failure.no_account")]
      elsif @email.present?
        @resource_error_messages[:email] = [I18n.t("activerecord.errors.models.user.attributes.email.invalid")]
      else
        @resource_error_messages[:email] = [I18n.t("activerecord.errors.models.user.attributes.email.blank")]
      end

      render :new if @resource_error_messages.present?
    end
  end

  def phone_code; end

  def phone_verify
    state = MultiFactorAuth.verify_code(login_state.user, params[:phone_code])
    if state == :ok
      record_security_event(SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_SUCCESS, user: login_state.user, factor: :sms, analytics: analytics_data)
      if params[:remember_me] == "1"
        token = MfaToken.generate!(login_state.user)
        cookies.encrypted[MFA_BYPASS_COOKIE_NAME] = {
          expires: MultiFactorAuth::BYPASS_TOKEN_EXPIRATION_AGE.after(token.created_at),
          httponly: true,
          secure: Rails.env.production?,
          value: (cookies.encrypted[MFA_BYPASS_COOKIE_NAME] || {}).merge(login_state.user.email => token.token),
        }
        record_security_event(SecurityActivity::ADDITIONAL_FACTOR_BYPASS_GENERATED, user: login_state.user, analytics: analytics_data)
      end
      do_sign_in(level_of_authentication: :level1)
      login_state.user.update!(last_mfa_success: Time.zone.now)
      login_state.destroy!
      session.delete(:login_state_id)
    else
      record_security_event(SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_FAILURE, user: login_state.user, factor: :sms, analytics: analytics_data)
      @phone_code_error_message = I18n.t("mfa.errors.phone_code.#{state}", resend_link: user_session_phone_resend_path)
      render :phone_code
    end
  end

  def phone_resend; end

  def phone_resend_code
    MultiFactorAuth.generate_and_send_code(login_state.user)
    redirect_to enter_phone_code_path
  end

  def destroy
    redirect_to account_delete_confirmation_path and return if params[:done] == "delete"

    redirect_to transition_path and return if all_signed_out?

    if params[:continue]
      current_user.invalidate_all_sessions!
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
      redirect_to "#{sign_out_path}?done=#{params[:continue]}"
    elsif params[:done]
      current_user.invalidate_all_sessions!
      super
      flash[:notice] = nil
    else
      redirect_to "#{sign_out_path}?continue=1"
    end
  end

protected

  def verify_signed_out_user; end

  def check_login_state
    @login_state_id = session[:login_state_id]
    redirect_to new_user_session_path unless login_state
  end

  def login_state
    @login_state ||=
      begin
        LoginState.find(@login_state_id)
      rescue ActiveRecord::RecordNotFound
        session.delete(:login_state_id)
        nil
      end
  end

  def do_sign_in(level_of_authentication:, has_level1_but_skipped_mfa: false)
    record_security_event(SecurityActivity::LOGIN_SUCCESS, user: login_state.user, analytics: analytics_data)

    cookies[:cookies_preferences_set] = "true"
    response["Set-Cookie"] = cookies_policy_header(login_state.user)

    sign_in(resource_name, login_state.user)

    session[:level_of_authentication] = level_of_authentication
    session[:has_done_mfa] =
      if level_of_authentication == :level1
        !has_level1_but_skipped_mfa
      else
        false
      end

    post_login_path =
      if login_state.redirect_path
        login_state.redirect_path
      elsif login_state.user.banned_password_match
        insecure_password_interstitial_path
      else
        user_root_path
      end

    redirect_to add_param_to_url(post_login_path, "_ga", params[:_ga])
  end

  def after_sign_out_path_for(_resource)
    transition_path
  end

  def enter_phone_code_path
    if params[:from_confirmation_email].present?
      user_session_phone_code_path(from_confirmation_email: params[:from_confirmation_email])
    else
      user_session_phone_code_path
    end
  end

  def resend_phone_code_path
    if params[:from_confirmation_email].present?
      user_session_phone_resend_path(from_confirmation_email: params[:from_confirmation_email])
    else
      user_session_phone_resend_path
    end
  end
  helper_method :resend_phone_code_path

  def analytics_data
    "from_confirmation_email" if params[:from_confirmation_email]
  end

  def sign_out_path
    base_url = Rails.env.development? ? Plek.find("frontend") : Plek.new.website_root
    "#{base_url}/sign-out"
  end
end
