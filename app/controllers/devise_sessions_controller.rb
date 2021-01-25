class DeviseSessionsController < Devise::SessionsController
  include AcceptsJwt
  include ApplicationHelper
  include CookiesHelper
  include UrlHelper

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
      self.resource = warden.authenticate(auth_options)
    end

    if resource
      if resource.banned_password_match.nil?
        resource.update!(banned_password_match: BannedPassword.is_password_banned?(params.dig(:user, :password)))
      end

      LoginState.transaction do
        jwt&.destroy_stale_states
        @login_state = LoginState.create!(
          created_at: Time.zone.now,
          user: resource,
          redirect_path: after_login_path(jwt&.jwt_payload, resource),
          jwt: jwt,
        )
        @login_state_id = login_state.id
      end
      session[:login_state_id] = @login_state_id

      if request.env["warden.mfa.required"]
        MultiFactorAuth.generate_and_send_code(resource)
        redirect_to enter_phone_code_path
      else
        do_sign_in
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
        redirect_to new_user_registration_start_path(user: { email: @email }) and return if jwt

        render "devise/registrations/transition_checker" and return if Rails.configuration.force_jwt_at_registration

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
      do_sign_in
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
      redirect_to "#{transition_checker_path}/logout?done=#{params[:continue]}"
    elsif params[:done]
      current_user.invalidate_all_sessions!
      super
      flash[:notice] = nil
    else
      redirect_to "#{transition_checker_path}/logout?continue=1"
    end
  end

protected

  def verify_signed_out_user; end

  def check_login_state
    @login_state_id = session[:login_state_id]
    redirect_to new_user_session_path unless login_state
  end

  def after_login_path(payload, user)
    payload&.dig("post_login_oauth").presence || after_sign_in_path_for(user)
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

  def do_sign_in
    record_security_event(SecurityActivity::LOGIN_SUCCESS, user: login_state.user, analytics: analytics_data)

    cookies[:cookies_preferences_set] = "true"
    response["Set-Cookie"] = cookies_policy_header(login_state.user)

    sign_in(resource_name, login_state.user)

    redirect_to add_param_to_url(login_state.redirect_path, "_ga", params[:_ga])
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
end
