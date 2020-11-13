class StandardErrorsController < ApplicationController
  before_action :report_error, only: %i[unprocessable_entity internal_server_error]

  def not_found
    respond_to do |format|
      format.html do
        @error = :not_found
        render status: :not_found, template: "standard_errors/generic"
      end
      format.all { head :not_found }
    end
  end

  def too_many_requests
    respond_to do |format|
      format.html do
        @error = :too_many_requests
        render status: :too_many_requests, template: "standard_errors/generic"
      end
      format.all { head :too_many_requests }
    end
  end

  def unprocessable_entity
    respond_to do |format|
      format.html do
        @error = :unprocessable_entity
        render status: :unprocessable_entity, template: "standard_errors/generic"
      end
      format.all { head :unprocessable_entity }
    end
  end

  def internal_server_error
    top_level_error_handler
  end

private

  def report_error
    error = request.env["action_dispatch.exception"]
    Raven::Rack.capture_exception(error, request.env) if error
  end
end
