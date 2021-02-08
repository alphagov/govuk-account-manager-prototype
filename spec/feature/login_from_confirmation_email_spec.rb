RSpec.feature "Logging in from confirmation email" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { FactoryBot.create(:user) }

  it "records extra information in the security activity when logging in" do
    enter_email_address_and_password
    enter_mfa

    expect(SecurityActivity.of_type(SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_SUCCESS).last.analytics).to eq("from_confirmation_email")
    expect(SecurityActivity.of_type(SecurityActivity::LOGIN_SUCCESS).last.analytics).to eq("from_confirmation_email")
  end

  it "records extra information in the security activity when logging in after requesting new MFA code" do
    enter_email_address_and_password
    request_new_mfa_code
    enter_mfa

    expect(SecurityActivity.of_type(SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_SUCCESS).last.analytics).to eq("from_confirmation_email")
    expect(SecurityActivity.of_type(SecurityActivity::LOGIN_SUCCESS).last.analytics).to eq("from_confirmation_email")
  end

  context "when the password is entered incorrectly" do
    it "records extra information in the security activity" do
      enter_email_address_and_password(password: "not-my-password")

      expect(SecurityActivity.of_type(SecurityActivity::LOGIN_FAILURE).last.analytics).to eq("from_confirmation_email")
    end
  end

  context "when the MFA code is entered incorrectly" do
    it "records extra information in the security activity" do
      enter_email_address_and_password
      enter_mfa(phone_code: "not valid")

      expect(SecurityActivity.of_type(SecurityActivity::ADDITIONAL_FACTOR_VERIFICATION_FAILURE).last.analytics).to eq("from_confirmation_email")
    end
  end

  def enter_email_address_and_password(email: user.email, password: user.password)
    visit user_confirmation_path(confirmation_token: user.confirmation_token)
    fill_in "email", with: email
    fill_in "password", with: password
    click_on I18n.t("devise.sessions.new.fields.submit.label")
  end

  def enter_mfa(phone_code: user.reload.phone_code)
    fill_in "phone_code", with: phone_code
    click_on I18n.t("mfa.phone.code.fields.submit.label")
  end

  def request_new_mfa_code
    click_on "send a new security code"
    click_on I18n.t("mfa.phone.resend.fields.submit.label")
  end
end
