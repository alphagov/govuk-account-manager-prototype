class ActivityController < ApplicationController
  before_action :authenticate_user!

  def show
    @activity = Services.keycloak.users.events(session[:sub])
  end
end
