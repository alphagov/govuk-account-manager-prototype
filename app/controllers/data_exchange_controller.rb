class DataExchangeController < ApplicationController
  before_action :authenticate_user!

  def show
    @data_exchanges = [] # TODO: implement
  end
end
