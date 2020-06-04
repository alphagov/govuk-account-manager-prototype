class CallbackController < ApplicationController
  def show
    result = Services.oidc.handle_redirect(params[:code], session[:nonce])
    session[:sub] = result[:user_info].sub
    redirect_to "/manage"
  end
end
