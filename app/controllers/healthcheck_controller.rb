class HealthcheckController < ApplicationController
  def show
    render json: Healthcheck.check
  end
end
