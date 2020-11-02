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
      if request.env["warden.mfa.required"]
        MultiFactorAuth.generate_and_send_code(resource)
        redirect_to user_session_phone_code_path(login_state_id: @login_state_id)
      else
        do_sign_in
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
      @phone_code_error_message = I18n.t("mfa.errors.phone_code.#{state}")
      render :phone_code
    end
  end

  def phone_resend; end

  def destroy
    if params[:continue]
      current_user.invalidate_all_sessions!
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
      redirect_to "#{transition_checker_path}/logout?done=1"
    elsif params[:done]
      current_user.invalidate_all_sessions!
      super
    else
      redirect_to "#{transition_checker_path}/logout?continue=1"
    end
  end

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

  def do_sign_in
    cookies[:cookies_preferences_set] = "true"
    response["Set-Cookie"] = cookies_policy_header(login_state.user)

    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, login_state.user)
    redirect_to login_state.redirect_path
  end
end
