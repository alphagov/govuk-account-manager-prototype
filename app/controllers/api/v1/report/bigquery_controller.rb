class Api::V1::Report::BigqueryController < Doorkeeper::ApplicationController
  skip_before_action :verify_authenticity_token

  before_action -> { doorkeeper_authorize! :reporting_access }

  respond_to :json

  def create
    end_date = params[:end_date] ? Time.zone.parse(params[:end_date]) : Time.zone.parse("15:00:00")
    head :bad_request and return if end_date.nil?

    start_date = params[:start_date] ? Time.zone.parse(params[:start_date]) : 1.day.before(end_date)
    head :bad_request and return if start_date.nil?

    BigqueryReportExportJob.perform_later(start_date, end_date)

    render status: :accepted, json: {
      start_date: start_date.strftime(Report::TIME_FORMAT),
      end_date: end_date.strftime(Report::TIME_FORMAT),
    }
  end
end
