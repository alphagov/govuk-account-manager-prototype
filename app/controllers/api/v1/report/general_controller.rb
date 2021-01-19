class Api::V1::Report::GeneralController < Doorkeeper::ApplicationController
  before_action -> { doorkeeper_authorize! :reporting_access }

  respond_to :json

  def show
    end_date = params[:end_date] ? Time.zone.parse(params[:end_date]) : Time.zone.parse("15:00:00")
    head 400 and return if end_date.nil?

    start_date = params[:start_date] ? Time.zone.parse(params[:start_date]) : 1.day.before(end_date)
    head 400 and return if start_date.nil?

    report = Report::GeneralStatistics.new(start_date: start_date, end_date: end_date)

    if params[:humanize]
      render json: [{ title: "Daily Statistics", text: report.humanize }]
    else
      out = report.report
      render json: out.merge(
        start_date: out[:start_date].strftime(Report::TIME_FORMAT),
        end_date: out[:end_date].strftime(Report::TIME_FORMAT),
      )
    end
  end
end
