module AccountHelper
  def finder_frontend_base_uri
    redirect_uri = Doorkeeper::Application.find_by(name: "Transition Checker").redirect_uri
    URI(redirect_uri).tap { |u| u.path = "" }.to_s
  end

  def email_alert_frontend_base_uri
    finder_frontend_base_uri.sub("finder-frontend", "email-alert-frontend")
  end
end
