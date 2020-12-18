class WelcomeController < ApplicationController
  include UrlHelper

  skip_before_action :verify_authenticity_token

  def show
    session[:jwt_id] = Jwt.create!(jwt_payload: params[:jwt]).id if params[:jwt]
    redirect_to add_param_to_url(destination_url, "_ga", params[:_ga])
  end

protected

  def destination_url
    if current_user
      after_sign_in_path_for(current_user)
    else
      new_user_registration_start_path
    end
  end
end
