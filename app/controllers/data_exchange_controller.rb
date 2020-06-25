class DataExchangeController < ApplicationController
  before_action :authenticate_user!

  def show
    @data_exchanges = Services.keycloak.users.consents(session[:sub])
  end
end
