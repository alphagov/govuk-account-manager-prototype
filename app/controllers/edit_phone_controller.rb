class EditPhoneController < ApplicationController
  include ChangeCoreCredentials

  before_action :authenticate_user!
  before_action :enforce_recent_mfa!

  helper_method :resource
  helper_method :setting_up_first_phone?
  helper_method :start_path

  def new
    redirect_to edit_user_registration_phone_path unless setting_up_first_phone?

    @resource_error_messages = {}
  end

  def show
    redirect_to edit_user_registration_phone_new_path if setting_up_first_phone?

    @resource_error_messages = {}
  end

  def confirm
    @resource_error_messages = {}

    unless current_user.valid_password? params[:current_password]
      @resource_error_messages[:current_password] = [
        I18n.t("activerecord.errors.models.user.attributes.password.#{params[:current_password].blank? ? 'blank' : 'invalid'}"),
      ]
    end

    if params[:phone]
      phone_number = MultiFactorAuth.e164_number(params[:phone])

      if phone_number == current_user.phone
        @resource_error_messages[:phone] = [
          I18n.t("mfa.errors.phone.nochange"),
        ]
      end

      unless MultiFactorAuth.valid? phone_number
        @resource_error_messages[:phone] = [
          I18n.t("activerecord.errors.models.user.attributes.phone.invalid"),
        ]
      end
    else
      @resource_error_messages[:phone] = [
        I18n.t("activerecord.errors.models.user.attributes.phone.blank"),
      ]
    end

    if @resource_error_messages.any?
      render setting_up_first_phone? ? :new : :show
    else
      current_user.update!(unconfirmed_phone: phone_number)
    end
  end

  def code
    @resource_error_messages = {}
  end

  def code_send
    redirect_to start_path and return unless current_user.unconfirmed_phone

    MultiFactorAuth.generate_and_send_code(current_user, use_unconfirmed: true)

    @resource_error_messages = {}
    render :code
  end

  def verify
    state = MultiFactorAuth.verify_code(current_user, params[:phone_code])
    if state == :ok
      old_phone = current_user.phone || "nothing"
      new_phone = current_user.unconfirmed_phone
      current_user.update!(
        phone: new_phone,
        unconfirmed_phone: nil,
        last_mfa_success: Time.zone.now,
      )
      record_security_event(SecurityActivity::PHONE_CHANGED, user: current_user, notes: "from #{old_phone} to #{new_phone}")
      UserMailer.with(user: current_user).change_phone_email.deliver_later
      session[:level_of_authentication] = :level1
      session[:has_done_mfa] = true
      redirect_to session.delete(:after_change_phone_path) || account_manage_path
    else
      @resource_error_messages = {
        phone_code: [
          I18n.t("mfa.errors.phone_code.#{state}", resend_link: edit_user_registration_phone_resend_path),
        ],
      }
      render :code
    end
  end

  def resend
    redirect_to start_path unless current_user.unconfirmed_phone
  end

private

  def resource; end

  def start_path
    if setting_up_first_phone?
      edit_user_registration_phone_new_path
    else
      edit_user_registration_phone_path
    end
  end

  def setting_up_first_phone?
    current_user.phone.nil?
  end

  def enforce_recent_mfa!
    redo_mfa edit_user_registration_phone_path if must_redo_mfa?
  end
end
