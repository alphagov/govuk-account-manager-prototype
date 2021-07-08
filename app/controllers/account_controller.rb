class AccountController < ApplicationController
  def show
    redirect_to user_root_path
  end
end
