class ProfileController < ApplicationController
  before_action :authenticate_user!

  def show
    @user_info = RemoteUserInfo.call(current_user)
  end
end
