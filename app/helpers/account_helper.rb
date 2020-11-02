module AccountHelper
  def email_alert_frontend_base_uri
    Plek.new.website_root
  end

  def paths_without_feedback_footer
    [
      feedback_form_path,
      feedback_form_submitted_path,
    ]
  end

  def feedback_enabled_page
    !paths_without_feedback_footer.include?(request.env["PATH_INFO"])
  end

  def flash_as_notice(notice)
    [
      I18n.t("devise.registrations.update_needs_confirmation"),
    ].include? notice
  end
end
