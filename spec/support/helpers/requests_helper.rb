module RequestsHelper
  def log_in(username, password)
    visit "/"
    fill_in "email", with: username
    click_on I18n.t("welcome.show.button.label")
    fill_in "password", with: password
    click_on I18n.t("devise.sessions.new.fields.submit.label")
  end
end

RSpec.configuration.send :include, RequestsHelper
