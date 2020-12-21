class ApplicationController < ActionController::Base
  include ActionView::Helpers::SanitizeHelper

  if ENV["REQUIRE_BASIC_AUTH"]
    http_basic_authenticate_with(
      name: ENV.fetch("BASIC_AUTH_USERNAME"),
      password: ENV.fetch("BASIC_AUTH_PASSWORD"),
    )
  end

  rescue_from Exception, with: :top_level_error_handler

  def record_security_event(event, options = {})
    SecurityActivity.record_event(
      event,
      {
        ip_address: request.remote_ip,
        user_agent_name: request.user_agent,
      }.merge(options),
    )
  end

protected

  def get_payload(payload_string = nil)
    jwt = if payload_string
            Jwt.create!(jwt_payload: payload_string)
              .tap { |j| session[:jwt_id] = j.id }
          elsif session[:jwt_id]
            Jwt.find(session[:jwt_id])
          end
    jwt&.jwt_payload&.deep_symbolize_keys
  rescue ActiveRecord::RecordNotFound
    session.delete(:jwt_id)
    nil
  end

  def top_level_error_handler(exception = nil)
    Raven.capture_exception(exception) if exception

    respond_to do |format|
      format.html do
        @error = :internal_server_error
        render status: :internal_server_error, template: "standard_errors/generic"
      end
      format.all { head :internal_server_error }
    end
  end

  def after_sign_in_path_for(_resource)
    target = params.fetch(:previous_url, user_root_path)
    if target.start_with?("/account") || target.start_with?("/oauth")
      target
    else
      user_root_path
    end
  end

  def destroy_stale_states(jwt_id)
    registration_states = RegistrationState.where(jwt_id: jwt_id).pluck(:id)
    login_states = LoginState.where(jwt_id: jwt_id).pluck(:id)

    RegistrationState.where(id: registration_states).update_all(jwt_id: nil)
    LoginState.where(id: login_states).update_all(jwt_id: nil)

    RegistrationState.where(id: registration_states).destroy_all
    LoginState.where(id: login_states).destroy_all
  end
end
