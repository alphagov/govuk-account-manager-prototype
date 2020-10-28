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
end
