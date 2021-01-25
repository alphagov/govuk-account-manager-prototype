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

    redirect_to add_param_to_url(new_user_registration_start_path, "_ga", params[:_ga])
  end

protected

  def after_login_path(payload, user)
    payload.dig("post_login_oauth").presence || after_sign_in_path_for(user)
  end
end
