RSpec.feature "Insecure Passwords" do
  let!(:user) { FactoryBot.create(:user) }

  before { BannedPassword.import_list([user.password]) }

  it "shows the interstitial page and the alert" do
    enter_email_address_and_password
    enter_mfa

    expect(page).to have_text(I18n.t("insecure_password.interstitial.heading"))

    continue_without_changing

    go_to_manage_page
    expect(page).to have_text(I18n.t("insecure_password.notice.message"))

    go_to_security_page
    expect(page).to have_text(I18n.t("insecure_password.notice.message"))
  end

  def enter_email_address_and_password(email: user.email, password: user.password)
    visit new_user_session_path
    fill_in "email", with: email
    fill_in "password", with: password
    click_on I18n.t("devise.sessions.new.fields.submit.label")
  end

  def enter_mfa(the_user: user)
    phone_code = the_user.reload.phone_code
    fill_in "phone_code", with: phone_code
    click_on I18n.t("mfa.phone.code.fields.submit.label")
  end

  def continue_without_changing
    click_on I18n.t("insecure_password.interstitial.ignore.link")
  end

  def go_to_manage_page
    visit account_manage_path
  end

  def go_to_security_page
    visit account_security_path
  end
end
