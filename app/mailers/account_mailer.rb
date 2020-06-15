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
end
