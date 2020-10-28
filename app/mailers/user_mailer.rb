class UserMailer < ApplicationMailer
  include ApplicationHelper

  def onboarding_email
    user = params[:user]
    @transition_checker_link = "#{transition_checker_path}/saved-results"
    @login_link = new_user_session_url
    @feedback_form_link = feedback_form_url
    mail(to: user.email, subject: I18n.t("mailer.onboarding.subject"))
  end
end
