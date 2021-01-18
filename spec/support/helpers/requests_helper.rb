module RequestsHelper
  def log_in(username: user.email, password: user.password)
    visit new_user_session_path
    fill_in "email", with: username
    fill_in "password", with: password
    click_on I18n.t("devise.sessions.new.fields.submit.label")

    if Rails.configuration.feature_flag_mfa
      fill_in "phone_code", with: user.reload.phone_code
      click_on I18n.t("mfa.phone.code.fields.submit.label")
    end
  end
end

RSpec.configuration.send :include, RequestsHelper
