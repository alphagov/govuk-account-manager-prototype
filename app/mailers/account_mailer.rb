class AccountMailer < ApplicationMailer
  self.delivery_job = EmailDeliveryJob

  def confirmation_email(email_address)
    @link = params[:link]
    mail(to: email_address, subject: I18n.t("emails.confirmation.subject"))
  end
end
