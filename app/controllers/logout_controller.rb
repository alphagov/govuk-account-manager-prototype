class LogoutController < ApplicationController
  def show
    session.delete(:sub)
    session.delete(:nonce)
    redirect_to "#{Services.oidc.end_session_endpoint}?post_logout_redirect_uri=https://www.gov.uk"
  end
end
