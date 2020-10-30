class UserMailer < ApplicationMailer
  include ApplicationHelper

  def onboarding_email
    user = params[:user]
    @transition_checker_link = "#{transition_checker_path}/saved-results"
    @login_link = new_user_session_url
    @feedback_form_link = feedback_form_url
    mail(to: user.email, subject: I18n.t("mailer.onboarding.subject"))
  end

  def change_phone_email
    user = params[:user]
    @login_link = new_user_session_url
    mail(to: user.email, subject: I18n.t("mailer.change_phone.subject"))
  end

  def post_delete_email
    email = params[:email]
    @feedback_form_link = feedback_form_url
    mail(to: email, subject: I18n.t("mailer.post_delete.subject"))
  end
end
