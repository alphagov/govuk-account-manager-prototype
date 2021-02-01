class WelcomeController < ApplicationController
  include AcceptsJwt
  include UrlHelper

  skip_before_action :verify_authenticity_token

  def show
    jwt = find_or_create_jwt(params[:jwt])

    if current_user
      redirect_to add_param_to_url(after_login_path(jwt.jwt_payload, current_user), "_ga", params[:_ga])
      return
    end

    path_to_redirect_to = jwt.jwt_payload.present? ? new_user_registration_start_path : new_user_session_path

    redirect_to add_param_to_url(path_to_redirect_to, "_ga", params[:_ga])
  end

protected

  def after_login_path(payload, user)
    payload.dig("post_login_oauth").presence || after_sign_in_path_for(user)
  end
end
