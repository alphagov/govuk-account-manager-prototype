class ApplicationController < ActionController::Base
  if ENV["REQUIRE_BASIC_AUTH"]
    http_basic_authenticate_with(
      name: ENV.fetch("BASIC_AUTH_USERNAME"),
      password: ENV.fetch("BASIC_AUTH_PASSWORD"),
    )
  end

  rescue_from Exception, with: :top_level_error_handler

  def after_sign_in_path_for(_resource)
    target = params[:previous_url] || user_root_path
    target = user_root_path if target =~ /\/login/
    target = user_root_path unless target.start_with? "/"
    target
  end

protected

  def top_level_error_handler(exception = nil)
    Raven.capture_exception(exception) if exception

    respond_to do |format|
      format.html do
        @error = :internal_server_error
        render status: :internal_server_error, template: "standard_errors/generic"
      end
      format.all { render status: :internal_server_error, nothing: true }
    end
  end
end
