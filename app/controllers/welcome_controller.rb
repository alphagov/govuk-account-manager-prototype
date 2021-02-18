class WelcomeController < ApplicationController
  include UrlHelper

  def show
    path_to_redirect_to = current_user ? after_sign_in_path_for(current_user) : new_user_session_path
    redirect_to add_param_to_url(path_to_redirect_to, "_ga", params[:_ga])
  end
end
