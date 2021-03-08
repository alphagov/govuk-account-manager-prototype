class RedoMfaPhoneController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_redirect_url!

  attr_reader :after_redo_mfa_url

  def code; end

  def verify
    state = MultiFactorAuth.verify_code(current_user, params[:phone_code])
    if state == :ok
      record_security_event(SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_SUCCESS, user: current_user, factor: :sms)

      session[:has_done_mfa] = true
      session.delete(:after_redo_mfa_url)
      current_user.update!(last_mfa_success: Time.zone.now)

      redirect_to after_redo_mfa_url
    else
      record_security_event(SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_FAILURE, user: current_user, factor: :sms)
      @phone_code_error_message = I18n.t("mfa.errors.phone_code.#{state}", resend_link: redo_mfa_phone_resend_path)
      render :code
    end
  end

  def resend; end

  def resend_code
    MultiFactorAuth.generate_and_send_code(current_user)
    redirect_to redo_mfa_phone_code_path
  end

protected

  def ensure_redirect_url!
    @after_redo_mfa_url = session[:after_redo_mfa_url]

    redirect_to user_root_path if after_redo_mfa_url.blank?
  end
end
