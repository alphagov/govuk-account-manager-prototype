module RequestsHelper
  def log_in(username, password)
    visit "/login"
    fill_in "email", with: username
    fill_in "password", with: password
    click_on I18n.t("devise.registrations.new.fields.submit.label")
  end
end

RSpec.configuration.send :include, RequestsHelper
