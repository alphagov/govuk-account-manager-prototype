class WelcomeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:show]

  def show
    payload = ApplicationKey.validate_jwt!(params[:jwt]) if params[:jwt]

    redirect_to after_login_path(payload, current_user) and return if current_user

    @email = params.dig(:user, :email)
    if @email
      if @email.blank?
        @email_error_message = I18n.t("activerecord.errors.models.user.attributes.email.blank")
        return
      end

      unless Devise.email_regexp.match? @email
        @email_error_message = I18n.t("activerecord.errors.models.user.attributes.email.invalid")
        return
      end

      if User.exists?(email: @email)
        login_state = create_login_state(payload, @email)
        session[:login_state_id] = login_state.id
        redirect_to user_session_path
      elsif Rails.configuration.enable_registration
        if payload || !Rails.configuration.force_jwt_at_registration
          registration_state = create_registration_state(payload, @email)
          session[:registration_state_id] = registration_state.id
          redirect_to new_user_registration_start_path
        else
          render "devise/registrations/transition_checker"
        end
      else
        render "devise/registrations/closed"
      end
    end
  end

protected

  def after_login_path(payload, user)
    payload&.dig(:post_login_oauth).presence || after_sign_in_path_for(user)
  end

  def create_login_state(payload, email)
    user = User.find_by(email: email).id

    LoginState.create!(
      created_at: Time.zone.now,
      user_id: user,
      redirect_path: after_login_path(payload, user),
    )
  end

  def create_registration_state(payload, email)
    RegistrationState.create!(
      touched_at: Time.zone.now,
      state: :start,
      email: email,
      previous_url: payload&.dig(:post_register_oauth).presence || params[:previous_url],
      jwt_payload: payload,
    )
  end
end
