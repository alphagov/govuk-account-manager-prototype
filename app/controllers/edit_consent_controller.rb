class EditConsentController < ApplicationController
  include CookiesHelper

  before_action :authenticate_user!

  def cookie; end

  def cookie_send
    cookie_consent = params[:cookie_consent] == "yes"
    current_user.update!(cookie_consent: cookie_consent)
    current_user.update_remote_user_info

    cookies[:cookies_preferences_set] = "true"
    response["Set-Cookie"] = cookies_policy_header(current_user.reload)

    flash[:notice] = I18n.t("account.manage.privacy.cookies_success")

    redirect_to(account_manage_path)
  end

  def feedback; end

  def feedback_send
    current_user.update!(feedback_consent: params[:feedback_consent] == "yes")
    current_user.update_remote_user_info

    flash[:notice] = I18n.t("account.manage.privacy.email_success")

    redirect_to(account_manage_path)
  end
end
