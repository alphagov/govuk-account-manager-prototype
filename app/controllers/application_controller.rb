class ApplicationController < ActionController::Base
  include ActionView::Helpers::SanitizeHelper

  if ENV["REQUIRE_BASIC_AUTH"]
    http_basic_authenticate_with(
      name: ENV.fetch("BASIC_AUTH_USERNAME"),
      password: ENV.fetch("BASIC_AUTH_PASSWORD"),
    )
  end

  rescue_from Exception, with: :top_level_error_handler

protected

  def get_payload(payload = nil)
    if payload
      jwt = Jwt.create!(
        jwt_payload: payload,
      )
      session[:jwt_id] = jwt.id
      payload
    elsif session[:jwt_id]
      jwt = Jwt.find(session[:jwt_id])
      jwt&.jwt_payload&.deep_symbolize_keys
    end
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
end
