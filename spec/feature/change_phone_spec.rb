RSpec.feature "Change Phone" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  before { allow(Rails.configuration).to receive(:feature_flag_mfa).and_return(true) }

  let(:user) { FactoryBot.create(:user) }

  let(:new_phone_number) { "07581123456" }

  it "updates the phone number" do
    log_in
    go_to_change_number_page
    enter_new_phone_number
    enter_password
    enter_mfa

    expect(page).to have_text(I18n.t("account.manage.heading"))
    expect(user.reload.phone).to eq("+447581123456")
  end

  it "shows the change phone event on the security page" do
    log_in
    go_to_change_number_page
    enter_new_phone_number
    enter_password
    enter_mfa
    visit_security_page

    expect(page).to have_text(I18n.t("account.security.event.phone_changed"))
  end

  context "when the user enters the same phone number" do
    it "returns an error" do
      log_in
      go_to_change_number_page
      enter_same_phone_number
      enter_password

      expect(page).to have_text(I18n.t("mfa.errors.phone.nochange"))
    end
  end

  context "when the phone number is not a mobile" do
    it "returns an error" do
      log_in
      go_to_change_number_page
      enter_non_mobile_phone_number
      enter_password

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.phone.invalid"))
    end
  end

  context "when the phone number is invalid" do
    it "returns an error" do
      log_in
      go_to_change_number_page
      enter_invalid_phone_number
      enter_password

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.phone.invalid"))
    end
  end

  context "when the password is incorrect" do
    it "returns an error" do
      log_in
      go_to_change_number_page
      enter_same_phone_number
      enter_incorrect_password

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.password.invalid"))
    end
  end

  context "when the MFA code is incorrect" do
    it "returns an error" do
      log_in
      go_to_change_number_page
      enter_new_phone_number
      enter_password
      enter_incorrect_mfa

      expect(page).to have_text(I18n.t("mfa.errors.phone_code.invalid"))
    end

    context "the user keeps entering an incorrect code" do
      it "expires the code" do
        log_in
        go_to_change_number_page
        enter_new_phone_number
        enter_password
        (MultiFactorAuth::ALLOWED_ATTEMPTS + 1).times { enter_incorrect_mfa }

        expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("mfa.errors.phone_code.too_many_attempts")))
      end
    end
  end

  context "when the MFA code is too old" do
    it "expires the code" do
      log_in
      go_to_change_number_page
      enter_new_phone_number
      enter_password
      travel(MultiFactorAuth::EXPIRATION_AGE + 1.second)
      enter_mfa

      expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("mfa.errors.phone_code.expired")))
    end
  end

  def log_in
    visit new_user_session_path
    fill_in "email", with: user.email
    fill_in "password", with: user.password
    click_on I18n.t("devise.sessions.new.fields.submit.label")

    fill_in "phone_code", with: user.reload.phone_code
    click_on I18n.t("mfa.phone.code.fields.submit.label")
  end

  def go_to_change_number_page
    within "#main-content" do
      click_on "Manage your account"
      click_on "Change Mobile number"
    end
  end

  def enter_new_phone_number
    fill_in "phone", with: new_phone_number
  end

  def enter_same_phone_number
    fill_in "phone", with: user.phone
  end

  def enter_non_mobile_phone_number
    fill_in "phone", with: "01234567890"
  end

  def enter_invalid_phone_number
    fill_in "phone", with: "999"
  end

  def enter_password
    fill_in "current_password", with: user.password
    click_on I18n.t("mfa.phone.update.start.fields.submit.label")
  end

  def enter_incorrect_password
    fill_in "current_password", with: "1#{user.password}"
    click_on I18n.t("mfa.phone.update.start.fields.submit.label")
  end

  def enter_mfa
    phone_code = user.reload.phone_code
    fill_in "phone_code", with: phone_code
    click_on I18n.t("mfa.phone.code.fields.submit.label")
  end

  def enter_incorrect_mfa
    phone_code = user.reload.phone_code
    fill_in "phone_code", with: "1#{phone_code}"
    click_on I18n.t("mfa.phone.code.fields.submit.label")
  end

  def visit_security_page
    click_on I18n.t("navigation.menu_bar.security.link_text")
  end
end
