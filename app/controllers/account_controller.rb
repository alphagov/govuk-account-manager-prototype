class AccountController < ApplicationController
  before_action :authenticate_user!

  def show
    @consents = Services.keycloak.users.consents(session[:sub])
    @sessions = Services.keycloak.users.sessions(session[:sub])
  end
end
