require "services"

class LogoutController < ApplicationController
  def show
    session.delete(:sub)

    redirect_to "#{Services.discover.end_session_endpoint}?post_logout_redirect_uri=https://www.gov.uk"
  end
end
