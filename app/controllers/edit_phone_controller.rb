class EditPhoneController < ApplicationController
  include ChangeCoreCredentials

  before_action :authenticate_user!
  before_action :enforce_has_phone!
  before_action :enforce_recent_mfa!

  def show; end

  def confirm
    unless current_user.valid_password? params[:current_password]
      @password_error_message = I18n.t("activerecord.errors.models.user.attributes.password.#{params[:current_password].blank? ? 'blank' : 'invalid'}")
    end

    if params[:phone]
      phone_number = MultiFactorAuth.e164_number(params[:phone])

      if phone_number == current_user.phone
        @phone_error_message = I18n.t("mfa.errors.phone.nochange")
      end

      unless MultiFactorAuth.valid? phone_number
        @phone_error_message = I18n.t("activerecord.errors.models.user.attributes.phone.invalid")
      end
    else
      @phone_error_message = I18n.t("activerecord.errors.models.user.attributes.phone.blank")
    end

    if @password_error_message || @phone_error_message
      render :show
    else
      current_user.update!(unconfirmed_phone: phone_number)
    end
  end

  def code; end

  def code_send
    redirect_to edit_user_registration_phone and return unless current_user.unconfirmed_phone

    MultiFactorAuth.generate_and_send_code(current_user, use_unconfirmed: true)

    render :code
  end

  def verify
    state = MultiFactorAuth.verify_code(current_user, params[:phone_code])
    if state == :ok
      old_phone = current_user.phone
      new_phone = current_user.unconfirmed_phone
      current_user.update!(
        phone: new_phone,
        unconfirmed_phone: nil,
        last_mfa_success: Time.zone.now,
      )
      record_security_event(SecurityActivity::PHONE_CHANGED, user: current_user, notes: "from #{old_phone} to #{new_phone}")
      UserMailer.with(user: current_user).change_phone_email.deliver_later
      redirect_to account_manage_path
    else
      @phone_code_error_message = I18n.t("mfa.errors.phone_code.#{state}", resend_link: edit_user_registration_phone_resend_path)
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

  def enforce_recent_mfa!
    redo_mfa edit_user_registration_phone_path if must_redo_mfa?
  end
end
