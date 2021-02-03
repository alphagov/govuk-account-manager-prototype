class InsecurePasswordController < ApplicationController
  before_action :authenticate_user!

  def show
    redirect_to user_root_path unless current_user.banned_password_match
  end
end
