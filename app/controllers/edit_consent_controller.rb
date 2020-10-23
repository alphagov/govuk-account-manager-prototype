class EditConsentController < ApplicationController
  before_action :authenticate_user!

  def cookie; end

  def cookie_send
    current_user.update!(cookie_consent: params[:cookie_consent] == "yes")
    redirect_to(account_manage_path)
  end

  def feedback; end

  def feedback_send
    current_user.update!(feedback_consent: params[:feedback_consent] == "yes")
    redirect_to(account_manage_path)
  end
end
