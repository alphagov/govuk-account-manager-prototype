class StandardErrorsController < ApplicationController
  before_action :report_error, only: %i[unprocessable_entity internal_server_error]

  def not_found
    error_page :not_found
  end

  def too_many_requests
    error_page :too_many_requests
  end

  def unprocessable_entity
    error_page :unprocessable_entity
  end

  def internal_server_error
    top_level_error_handler
  end

private

  def report_error
    error = request.env["action_dispatch.exception"]
    GovukError.notify(error) if error
  end
end
