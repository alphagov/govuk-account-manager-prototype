class EditPhoneController < ApplicationController
  before_action :authenticate_user!
  before_action :enforce_has_phone!

  def show; end

  def code; end

  def code_send
    phone_number = [nil, ""].include?(params[:phone]) ? current_user.unconfirmed_phone : params[:phone]

    unless TelephoneNumber.valid?(phone_number, :gb)
      @phone_error_message = I18n.t("mfa.errors.phone.invalid")
      render :show
      return
    end

    if phone_number == current_user.phone
      @phone_error_message = I18n.t("mfa.errors.phone.nochange")
      render :show
      return
    end

    current_user.transaction do
      current_user.update!(unconfirmed_phone: phone_number)
      MultiFactorAuth.generate_and_send_code(current_user, use_unconfirmed: true)
    end

    render :code
  end

  def verify
    state = MultiFactorAuth.verify_code(current_user, params[:phone_code])
    if state == :ok
      current_user.update!(
        phone: current_user.unconfirmed_phone,
        unconfirmed_phone: nil,
        last_mfa_success: Time.zone.now,
      )
      Activity.change_phone!(
        current_user,
        request.remote_ip,
      )
      redirect_to edit_user_registration_phone_done_path
    else
      @phone_code_error_message = I18n.t("mfa.errors.phone_code.#{state}")
      render :code
    end
  end

  def resend; end

  def done; end

protected

  def enforce_has_phone!
    redirect_to user_root_path unless current_user.phone
  end
end
