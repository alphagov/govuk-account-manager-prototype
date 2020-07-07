require "services"

class LogoutController < ApplicationController
  def show
    if session[:sub]
      Services.keycloak.users.logout(session[:sub])
      session.delete(:sub)
    end

    session.delete(:keycloak_cookies)

    # TODO: we should restrict this URI to avoid an open redirect
    redirect_to logout_params.fetch(:post_logout_redirect_uri, "https://www.gov.uk")
  end

private

  def logout_params
    params.permit(:post_logout_redirect_uri)
  end
end
