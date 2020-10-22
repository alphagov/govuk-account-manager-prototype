class EditConsentController < ApplicationController
  before_action :authenticate_user!

  def feedback; end

  def feedback_send
    current_user.update!(feedback_consent: params[:feedback_consent] == "yes")
    redirect_to(account_manage_path)
  end
end
