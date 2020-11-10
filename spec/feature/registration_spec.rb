RSpec.feature "Registration" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  before { allow(Rails.configuration).to receive(:feature_flag_mfa).and_return(mfa_enabled) }
  before { allow(Rails.configuration).to receive(:enable_registration).and_return(registration_enabled) }
  before { allow(Rails.configuration).to receive(:force_jwt_at_registration).and_return(force_jwt) }

  let(:mfa_enabled) { true }
  let(:registration_enabled) { true }
  let(:force_jwt) { false }
  let(:email) { "email@example.com" }
  # https://www.ofcom.org.uk/phones-telecoms-and-internet/information-for-industry/numbering/numbers-for-drama
  let(:phone_number) { "07958 123 456" }
  let(:password) { "abcd1234" } # pragma: allowlist secret
  let(:password_confirmation) { password }

  it "creates a user" do
    enter_email_address
    enter_password_and_confirmation
    enter_phone_number
    enter_mfa
    provide_consent

    expect(page).to have_text(I18n.t("post_registration.heading"))

    expect(User.last).to_not be_nil
    expect(User.last.email).to eq(email)
    expect(User.last.phone).to eq("+447958123456")
  end

  it "sends an email" do
    enter_email_address
    enter_password_and_confirmation
    enter_phone_number
    enter_mfa
    provide_consent

    assert_enqueued_jobs 1, only: NotifyDeliveryJob
  end

  it "shows the MFA page" do
    enter_email_address
    enter_password_and_confirmation

    expect(page).to have_text(I18n.t("mfa.phone.create.fields.phone.label"))
  end

  it "shows the terms & conditions" do
    enter_email_address
    enter_password_and_confirmation
    enter_phone_number
    enter_mfa

    expect(page).to have_text(I18n.t("devise.registrations.your_information.heading"))
  end

  context "when the email is missing" do
    let(:email) { "" }

    it "shows an error" do
      enter_email_address

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.blank"))
    end
  end

  context "when the email is missing an '@'" do
    let(:email) { "foo" }

    it "shows an error" do
      enter_email_address

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.blank"))
    end
  end

  context "when the email is missing a '.' after the '@'" do
    let(:email) { "foo@bar" }

    it "shows an error" do
      enter_email_address

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.blank"))
    end
  end

  context "when the email has multiple '@'s" do
    let(:email) { "foo@bar@baz" }

    it "shows an error" do
      enter_email_address

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.blank"))
    end
  end

  context "when the password is missing" do
    let(:password) { "" }

    it "returns an error" do
      enter_email_address
      enter_password_and_confirmation

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.password.blank"))
    end
  end

  context "when the password confirmation is missing" do
    let(:password_confirmation) { "" }

    it "returns an error" do
      enter_email_address
      enter_password_and_confirmation

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.password_confirmation.confirmation"))
    end
  end

  context "when the password confirmation does not match" do
    let(:password_confirmation) { password + "-123" }

    it "returns an error" do
      enter_email_address
      enter_password_and_confirmation

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.password_confirmation.confirmation"))
    end
  end

  context "when the password is less than 8 characters" do
    let(:password) { "qwerty1" }

    it "returns an error" do
      enter_email_address
      enter_password_and_confirmation

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.password.too_short"))
    end
  end

  context "when the phone number is not a mobile" do
    it "returns an error" do
      enter_email_address
      enter_password_and_confirmation
      enter_non_mobile_phone_number

      expect(page).to have_text(I18n.t("mfa.errors.phone.invalid"))
    end
  end

  context "when the phone number is invalid" do
    it "returns an error" do
      enter_email_address
      enter_password_and_confirmation
      enter_invalid_phone_number

      expect(page).to have_text(I18n.t("mfa.errors.phone.invalid"))
    end
  end

  context "when the MFA code is incorrect" do
    it "returns an error" do
      enter_email_address
      enter_password_and_confirmation
      enter_phone_number
      enter_incorrect_mfa

      expect(page).to have_text(I18n.t("mfa.errors.phone_code.invalid"))
    end

    context "the user keeps entering an incorrect code" do
      it "expires the code" do
        enter_email_address
        enter_password_and_confirmation
        enter_phone_number
        (MultiFactorAuth::ALLOWED_ATTEMPTS + 1).times { enter_incorrect_mfa }

        expect(page).to have_text(I18n.t("mfa.errors.phone_code.expired"))
      end
    end
  end

  context "when the MFA code is too old" do
    it "expires the code" do
      enter_email_address
      enter_password_and_confirmation
      enter_phone_number
      travel(MultiFactorAuth::EXPIRATION_AGE + 1.second)
      enter_mfa

      expect(page).to have_text(I18n.t("mfa.errors.phone_code.expired"))
    end
  end

  context "the user tries to skip over the MFA pages and go straight to the 'your information' page" do
    it "redirects them back to the first MFA page" do
      enter_email_address
      enter_password_and_confirmation
      query = current_url.split("?")[1]
      visit "#{new_user_registration_your_information_path}?#{query}"

      expect(page).to have_text(I18n.t("mfa.phone.create.fields.phone.label"))
    end
  end

  context "MFA is disabled" do
    let(:mfa_enabled) { false }

    it "skips over the MFA screens" do
      enter_email_address
      enter_password_and_confirmation
      provide_consent

      expect(page).to have_text(I18n.t("post_registration.heading"))

      expect(User.last).to_not be_nil
      expect(User.last.email).to eq(email)
      expect(User.last.phone).to be_nil
    end
  end

  context "registrations are disabled" do
    let(:registration_enabled) { false }

    it "shows an error message" do
      enter_email_address

      expect(page).to have_text(I18n.t("devise.registrations.closed.heading"))
    end
  end

  context "a JWT is required" do
    let(:force_jwt) { true }

    it "shows an error message" do
      enter_email_address

      expect(page).to have_text(I18n.t("devise.registrations.transition_checker.heading"))
    end
  end

  def enter_email_address
    visit "/"
    fill_in "email", with: email
    click_on I18n.t("welcome.show.button.label")
  end

  def enter_password_and_confirmation
    fill_in "password", with: password
    fill_in "password_confirmation", with: password_confirmation
    click_on I18n.t("devise.registrations.start.fields.submit.label")
  end

  def enter_phone_number
    fill_in "phone", with: phone_number
    click_on I18n.t("mfa.phone.create.fields.submit.label")
  end

  def enter_non_mobile_phone_number
    fill_in "phone", with: "01234567890"
    click_on I18n.t("mfa.phone.create.fields.submit.label")
  end

  def enter_invalid_phone_number
    fill_in "phone", with: "999"
    click_on I18n.t("mfa.phone.create.fields.submit.label")
  end

  def enter_mfa
    phone_code = RegistrationState.last.phone_code
    fill_in "phone_code", with: phone_code
    click_on I18n.t("mfa.phone.code.fields.submit.label")
  end

  def enter_incorrect_mfa
    phone_code = RegistrationState.last.phone_code
    fill_in "phone_code", with: "1#{phone_code}"
    click_on I18n.t("mfa.phone.code.fields.submit.label")
  end

  def provide_consent
    find(:css, "input[name='cookie_consent'][value='yes']").set(true)
    find(:css, "input[name='feedback_consent'][value='no']").set(true)
    click_on I18n.t("devise.registrations.your_information.fields.submit.label")
  end
end
