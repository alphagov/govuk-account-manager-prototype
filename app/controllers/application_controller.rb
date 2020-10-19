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
end
