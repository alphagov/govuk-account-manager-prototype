class SessionsController < ApplicationController
  def create
    session[:sub] = auth_hash[:uid]
    session[:refresh_token] = auth_hash[:credentials][:access_token].refresh_token
    redirect_to auth_hash[:extra][:return_to]
  end

protected

  def auth_hash
    request.env["omniauth.auth"]
  end
end
