class ApplicationController < ActionController::Base
  include ActionView::Helpers::SanitizeHelper

  if ENV["REQUIRE_BASIC_AUTH"]
    http_basic_authenticate_with(
      name: ENV.fetch("BASIC_AUTH_USERNAME"),
      password: ENV.fetch("BASIC_AUTH_PASSWORD"),
    )
  end

  rescue_from Exception, with: :top_level_error_handler

  rescue_from ActionController::InvalidAuthenticityToken do
    error_page :unprocessable_entity
  end

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

  def error_page(error)
    respond_to do |format|
      format.html do
        @error = error
        render status: error, template: "standard_errors/generic"
      end
      format.all { head error }
    end
  end

  def top_level_error_handler(exception = nil)
    GovukError.notify(exception) if exception

    error_page :internal_server_error
  end

  def after_sign_in_path_for(_resource)
    target = params.fetch(:previous_url, user_root_path)
    if target.start_with?("/account") || target.start_with?("/oauth")
      target
    else
      user_root_path
    end
  end

  def sign_out_path
    base_url = Rails.env.development? ? Plek.find("frontend") : Plek.new.website_root
    "#{base_url}/sign-out"
  end
end
