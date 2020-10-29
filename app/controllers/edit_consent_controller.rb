class EditConsentController < ApplicationController
  before_action :authenticate_user!

  def cookie; end

  def cookie_send
    cookie_consent = params[:cookie_consent] == "yes"
    current_user.update!(cookie_consent: cookie_consent)

    cookies[:cookies_preferences_set] = "true"
    response["Set-Cookie"] = "cookies_policy={\"essential\": true, \"settings\": false, \"usage\": #{cookie_consent}, \"campaigns\": false}"

    redirect_to(account_manage_path)
  end

  def feedback; end

  def feedback_send
    current_user.update!(feedback_consent: params[:feedback_consent] == "yes")
    redirect_to(account_manage_path)
  end
end
