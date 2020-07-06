class AccountMailer < ApplicationMailer
  self.delivery_job = EmailDeliveryJob

  def confirmation_email(email_address)
    @link = params[:link]
    mail(to: email_address, subject: I18n.t("emails.confirmation.subject"))
  end

  def reset_password_email(email_address)
    @link = params[:link]
    mail(to: email_address, subject: I18n.t("emails.reset_password.subject"))
  end

  def change_confirmation_email(email_address)
    @link = params[:link]
    mail(to: email_address, subject: I18n.t("emails.change_confirmation.subject"))
  end

  def change_cancel_email(email_address)
    @new_address = params[:new_address]
    @link = params[:link]
    mail(to: email_address, subject: I18n.t("emails.change_cancel.subject"))
  end
end
