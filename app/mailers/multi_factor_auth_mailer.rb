class MultiFactorAuthMailer < ApplicationMailer
  def phone_change
    @email = params[:user].email
    mail(to: @email, subject: I18n.t("mfa.mailer.phone_change.subject"))
  end
end
