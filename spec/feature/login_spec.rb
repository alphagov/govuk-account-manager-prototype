RSpec.feature "Logging in" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  before { allow(Rails.configuration).to receive(:feature_flag_mfa).and_return(mfa_enabled) }

  let(:mfa_enabled) { true }

  let!(:user) do
    FactoryBot.create(
      :user,
      email: email,
      phone: phone_number,
      password: password,
      password_confirmation: password,
    )
  end

  let(:email) { "email@example.com" }
  let(:password) { "abcd1234" } # pragma: allowlist secret
  let(:phone_number) { "01234567890" }

  it "logs the user in" do
    enter_email_address
    enter_password
    enter_mfa

    expect(page).to have_text(I18n.t("account.your_account.heading"))
  end

  it "shows the MFA page" do
    enter_email_address
    enter_password

    expect(page).to have_text(I18n.t("devise.sessions.phone_code.fields.phone_code.label"))
  end

  context "the password is incorrect" do
    it "returns an error" do
      enter_email_address
      enter_incorrect_password

      expect(page).to have_text(I18n.t("devise.sessions.new.fields.password.errors.incorrect"))
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

      expect(page).to have_text(I18n.t("devise.sessions.phone_code.errors.invalid"))
    end

    context "the user keeps entering an incorrect code" do
      it "expires the code" do
        enter_email_address
        enter_password
        (MultiFactorAuth::ALLOWED_ATTEMPTS + 1).times { enter_incorrect_mfa }

        expect(page).to have_text(I18n.t("devise.sessions.phone_code.errors.expired"))
      end
    end
  end

  context "the MFA code is too old" do
    it "expires the code" do
      enter_email_address
      enter_password
      travel(MultiFactorAuth::EXPIRATION_AGE + 1.second)
      enter_mfa

      expect(page).to have_text(I18n.t("devise.sessions.phone_code.errors.expired"))
    end
  end

  context "the user doesn't have a phone number" do
    let(:phone_number) { nil }

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

  def enter_email_address
    visit "/"
    fill_in "email", with: email
    click_on I18n.t("welcome.show.button.label")
  end

  def enter_password
    fill_in "password", with: password
    click_on I18n.t("devise.sessions.new.fields.submit.label")
  end

  def enter_incorrect_password
    fill_in "password", with: "1#{password}"
    click_on I18n.t("devise.sessions.new.fields.submit.label")
  end

  def enter_mfa
    phone_code = user.reload.phone_code
    fill_in "phone_code", with: phone_code
    click_on I18n.t("devise.sessions.phone_code.fields.submit.label")
  end

  def enter_incorrect_mfa
    phone_code = user.reload.phone_code
    fill_in "phone_code", with: "1#{phone_code}"
    click_on I18n.t("devise.sessions.phone_code.fields.submit.label")
  end

  def go_straight_to_account_page
    visit user_root_path
  end
end