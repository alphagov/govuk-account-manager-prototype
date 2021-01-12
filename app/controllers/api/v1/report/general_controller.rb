class Api::V1::Report::GeneralController < Doorkeeper::ApplicationController
  before_action -> { doorkeeper_authorize! :reporting_access }

  respond_to :json

  rescue_from ActionController::ParameterMissing do
    head 400
  end

  def show
    start_date = params.fetch(:start_date)
    end_date = params.fetch(:end_date)

    report = Report::GeneralStatistics.new(start_date: start_date, end_date: end_date)

    if params[:humanize]
      render json: [{ title: "Daily Statistics", text: report.humanize }]
    else
      render json: report.report
    end
  end
end
