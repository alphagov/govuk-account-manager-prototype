RSpec.feature "Logging in" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  before { allow(Rails.configuration).to receive(:feature_flag_mfa).and_return(mfa_enabled) }

  let(:mfa_enabled) { true }

  let!(:user) { FactoryBot.create(:user) }

  it "logs the user in" do
    enter_email_address
    enter_password
    enter_mfa

    expect(page).to have_text(I18n.t("account.your_account.heading"))
  end

  it "shows the MFA page" do
    enter_email_address
    enter_password

    expect(page).to have_text(I18n.t("mfa.phone.code.fields.phone_code.label"))
  end

  context "the password is incorrect" do
    it "returns an error" do
      enter_email_address
      enter_incorrect_password

      expect(page).to have_text(I18n.t("devise.sessions.new.fields.password.errors.incorrect"))
    end
  end

  context "the user tries to bypass password check" do
    it "does not send MFA code" do
      enter_email_address
      go_straight_to_mfa_page

      expect(page).to_not have_text(I18n.t("mfa.phone.code.sign_in_heading"))
    end
  end

  context "the user tries to bypass MFA" do
    it "does not log them in" do
      enter_email_address
      enter_password
      go_straight_to_account_page

      expect(page).to_not have_text(I18n.t("account.your_account.heading"))
    end
  end

  context "the MFA code is incorrect" do
    it "returns an error" do
      enter_email_address
      enter_password
      enter_incorrect_mfa

      expect(page).to have_text(I18n.t("mfa.errors.phone_code.invalid"))
    end

    context "the user keeps entering an incorrect code" do
      it "expires the code" do
        enter_email_address
        enter_password
        (MultiFactorAuth::ALLOWED_ATTEMPTS + 1).times { enter_incorrect_mfa }

        expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("mfa.errors.phone_code.too_many_attempts")))
      end
    end
  end

  context "the MFA code is too old" do
    it "expires the code" do
      enter_email_address
      enter_password
      travel(MultiFactorAuth::EXPIRATION_AGE + 1.second)
      enter_mfa

      expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("mfa.errors.phone_code.expired")))
    end
  end

  context "the user doesn't have a phone number" do
    before { user.update!(phone: nil) }

    it "skips over the MFA screen" do
      enter_email_address
      enter_password

      expect(page).to have_text(I18n.t("account.your_account.heading"))
    end
  end

  context "MFA is disabled" do
    let(:mfa_enabled) { false }

    it "skips over the MFA screen" do
      enter_email_address
      enter_password

      expect(page).to have_text(I18n.t("account.your_account.heading"))
    end
  end

  context "user has not confirmed email address" do
    it "allows login when confirmation was sent less than 7 days ago" do
      user.update!(confirmation_sent_at: Time.zone.now - 6.days)

      enter_email_address
      enter_password
      enter_mfa

      expect(page).to have_text(I18n.t("account.your_account.heading"))
    end

    it "shows an error when confirmation was sent more than 7 days ago" do
      user.update!(confirmation_sent_at: Time.zone.now - 7.days)

      enter_email_address
      enter_password

      expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("devise.failure.unconfirmed")))
    end
  end

  def enter_email_address
    visit new_user_session_path
    fill_in "email", with: user.email
    click_on I18n.t("welcome.show.button.label")
  end

  def enter_password
    fill_in "password", with: user.password
    click_on I18n.t("devise.sessions.new.fields.submit.label")
  end

  def enter_incorrect_password
    fill_in "password", with: "1#{user.password}"
    click_on I18n.t("devise.sessions.new.fields.submit.label")
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

  def go_straight_to_mfa_page
    visit user_session_phone_code_path
  end

  def go_straight_to_account_page
    visit user_root_path
  end
end
