class SessionsController < ApplicationController
  def create
    session[:sub] = auth_hash[:uid]
    redirect_to "/account/manage"
  end

protected

  def auth_hash
    request.env["omniauth.auth"]
  end
end
