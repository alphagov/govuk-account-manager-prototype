class AccountController < ApplicationController
  before_action :authenticate_user!

  def show
    @user_info = Rails.cache.fetch("remote_user_info/#{current_user.id}", expires_in: 5.minutes) do
      RemoteUserInfo.call(current_user)
    end
  end
end
