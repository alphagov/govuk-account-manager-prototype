require "reset_password"

class ChangePasswordController < ApplicationController
  before_action :authenticate_user!

  def show; end

  def submit
    ResetPassword.send(@user)
  end
end
