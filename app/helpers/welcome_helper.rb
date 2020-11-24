module WelcomeHelper
  def notice_to_show(notice)
    [
      I18n.t("devise.confirmations.confirmed"),
      I18n.t("devise.passwords.updated_not_active"),
      I18n.t("errors.messages.already_confirmed"),
    ].include? notice
  end
end
