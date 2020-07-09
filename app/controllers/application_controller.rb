class ApplicationController < ActionController::Base
  if ENV["REQUIRE_BASIC_AUTH"]
    http_basic_authenticate_with(
      name: ENV.fetch("BASIC_AUTH_USERNAME"),
      password: ENV.fetch("BASIC_AUTH_PASSWORD"),
    )
  end

  def after_sign_in_path_for(_resource)
    target = params[:previous_url] || user_root_path
    target = user_root_path if target =~ /\/login/
    target = user_root_path unless target.start_with? "/"
    target
  end
end
