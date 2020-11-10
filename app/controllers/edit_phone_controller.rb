class EditPhoneController < ApplicationController
  before_action :authenticate_user!
  before_action :enforce_has_phone!

  def show; end

  def code; end

  def code_send
    phone_number = current_user.unconfirmed_phone

    if params[:phone]
      phone_number = if TelephoneNumber.valid?(params[:phone], :gb)
                       TelephoneNumber.parse(params[:phone], :gb).e164_number
                     else
                       TelephoneNumber.parse(params[:phone]).e164_number
                     end

      unless current_user.valid_password? params[:current_password]
        @password_error_message = I18n.t("activerecord.errors.models.user.attributes.password.#{params[:current_password].blank? ? 'blank' : 'invalid'}")
      end

      if phone_number == current_user.phone
        @phone_error_message = I18n.t("mfa.errors.phone.nochange")
      end

      unless MultiFactorAuth.valid? phone_number
        @phone_error_message = I18n.t("mfa.errors.phone.invalid")
      end

      render :show and return if @password_error_message || @phone_error_message
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
      SecurityActivity.change_phone!(
        current_user,
        request.remote_ip,
      )
      UserMailer.with(user: current_user).change_phone_email.deliver_later
      redirect_to account_manage_path
    else
      @phone_code_error_message = I18n.t("mfa.errors.phone_code.#{state}")
      render :code
    end
  end

  def resend
    redirect_to edit_user_registration_phone unless current_user.unconfirmed_phone
  end

protected

  def enforce_has_phone!
    redirect_to user_root_path unless current_user.phone
  end
end
