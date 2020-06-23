class DataExchangeController < ApplicationController
  before_action :authenticate_user!

  def show
    @data_exchange = {}
  end
end
