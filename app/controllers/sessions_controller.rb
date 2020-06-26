class SessionsController < ApplicationController
  def create
    session[:sub] = auth_hash[:uid]
    redirect_to auth_hash[:extra][:return_to]
  end

protected

  def auth_hash
    request.env["omniauth.auth"]
  end
end
