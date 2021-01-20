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
  let(:password) { "abcd1234" }

  it "creates a user" do
    visit_registration_form
    enter_email_address
    enter_password
    enter_uk_phone_number
    submit_registration_form
    enter_mfa
    provide_consent

    expect(page).to have_text(I18n.t("confirmation_sent.heading"))

    expect(User.last).to_not be_nil
    expect(User.last.email).to eq(email)
    expect(User.last.phone).to eq("+447958123456")
    expect(User.last.cookie_consent).to be(true)
    expect(User.last.feedback_consent).to be(false)
  end

  it "sends an email" do
    visit_registration_form
    enter_email_address
    enter_password
    enter_uk_phone_number
    submit_registration_form
    enter_mfa
    provide_consent

    assert_enqueued_jobs 1, only: NotifyDeliveryJob
  end

  it "shows an account created security event" do
    visit_registration_form
    enter_email_address
    enter_password
    enter_uk_phone_number
    submit_registration_form
    enter_mfa
    provide_consent
    visit_user_account_dashboard
    click_on_security
    i_see_an_account_created_event
  end

  it "shows the MFA page" do
    visit_registration_form
    enter_email_address
    enter_password
    enter_uk_phone_number
    submit_registration_form

    expect(page).to have_text(I18n.t("mfa.phone.code.sign_up_heading"))
  end

  it "shows the terms & conditions" do
    visit_registration_form
    enter_email_address
    enter_password
    enter_uk_phone_number
    submit_registration_form
    enter_mfa

    expect(page).to have_text(I18n.t("devise.registrations.your_information.heading"))
  end

  context "when the email is missing" do
    let(:email) { "" }

    it "shows an error" do
      visit_registration_form
      enter_email_address
      submit_registration_form

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.blank"))
    end
  end

  context "when the email is missing an '@'" do
    let(:email) { "foo" }

    it "shows an error" do
      visit_registration_form
      enter_email_address
      submit_registration_form

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.invalid"))
    end
  end

  context "when the email is missing a '.' after the '@'" do
    let(:email) { "foo@bar" }

    it "shows an error" do
      visit_registration_form
      enter_email_address
      submit_registration_form

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.invalid"))
    end
  end

  context "when the email has multiple '@'s" do
    let(:email) { "foo@bar@baz" }

    it "shows an error" do
      visit_registration_form
      enter_email_address
      submit_registration_form

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.invalid"))
    end
  end

  context "when the user already exists" do
    let!(:user) { FactoryBot.create(:user) }

    it "shows an error" do
      visit_registration_form
      fill_in "email", with: user.email
      submit_registration_form

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.taken"))
    end
  end

  context "when the password is missing" do
    let(:password) { "" }

    it "returns an error" do
      visit_registration_form
      enter_email_address
      enter_password
      submit_registration_form

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.password.blank"))
    end
  end

  context "when the password is less than 8 characters" do
    let(:password) { "qwerty1" }

    it "returns an error" do
      visit_registration_form
      enter_email_address
      enter_password
      submit_registration_form

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.password.too_short"))
    end
  end

  context "when the password is on the denylist" do
    let(:password) { "password-to-deny" }

    before do
      BannedPassword.import_list([password])
    end

    it "returns an error" do
      visit_registration_form
      enter_email_address
      enter_password
      submit_registration_form

      expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("activerecord.errors.models.user.attributes.password.denylist")))
    end
  end

  context "when the phone number is not a mobile" do
    it "returns an error" do
      visit_registration_form
      enter_email_address
      enter_password
      enter_non_mobile_phone_number
      submit_registration_form

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.phone.invalid"))
    end
  end

  context "when the phone number is invalid" do
    it "returns an error" do
      visit_registration_form
      enter_email_address
      enter_password
      enter_invalid_phone_number
      submit_registration_form

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.phone.invalid"))
    end
  end

  context "when the phone number is from the Crown Dependencies" do
    valid_numbers = %w[07624123456 07797987654 07700123456 07829123456 07781123456 07839123456 07911123456]

    valid_numbers.each do |valid_number|
      context "with example number #{valid_number}" do
        it "sends an email" do
          visit_registration_form
          enter_email_address
          enter_password
          enter_phone_number(valid_number)
          submit_registration_form
          enter_mfa
          provide_consent

          assert_enqueued_jobs 1, only: NotifyDeliveryJob
          expect(User.last.phone).to eq("+44#{valid_number.gsub(/^0/, '')}")
        end
      end
    end
  end

  context "when the phone number is international" do
    it "sends an email" do
      visit_registration_form
      enter_email_address
      enter_password
      enter_international_phone_number
      submit_registration_form
      enter_mfa
      provide_consent

      assert_enqueued_jobs 1, only: NotifyDeliveryJob
      expect(User.last.phone).to eq("+15417543010")
    end
  end

  context "when the phone number is international with 00 instead of +" do
    it "sends an email" do
      visit_registration_form
      enter_email_address
      enter_password
      enter_international_phone_number_without_plus
      submit_registration_form
      enter_mfa
      provide_consent

      assert_enqueued_jobs 1, only: NotifyDeliveryJob
      expect(User.last.phone).to eq("+15417543010")
    end
  end

  context "when the MFA code is incorrect" do
    it "returns an error" do
      visit_registration_form
      enter_email_address
      enter_password
      enter_uk_phone_number
      submit_registration_form
      enter_incorrect_mfa

      expect(page).to have_text(I18n.t("mfa.errors.phone_code.invalid"))
    end

    context "the user keeps entering an incorrect code" do
      it "expires the code" do
        visit_registration_form
        enter_email_address
        enter_password
        enter_uk_phone_number
        submit_registration_form
        (MultiFactorAuth::ALLOWED_ATTEMPTS + 1).times { enter_incorrect_mfa }

        expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("mfa.errors.phone_code.too_many_attempts")))
      end

      it "lets the user request a new code" do
        visit_registration_form
        enter_email_address
        enter_password
        enter_uk_phone_number
        submit_registration_form
        (MultiFactorAuth::ALLOWED_ATTEMPTS + 1).times { enter_incorrect_mfa }
        request_new_mfa_code
        enter_mfa
        provide_consent

        expect(page).to have_text(I18n.t("confirmation_sent.heading"))
      end
    end
  end

  context "when the MFA code is too old" do
    it "expires the code" do
      visit_registration_form
      enter_email_address
      enter_password
      enter_uk_phone_number
      submit_registration_form
      travel(MultiFactorAuth::EXPIRATION_AGE + 1.second)
      enter_mfa
      user_is_returned_to_registration_start
    end
  end

  context "the user tries to skip over the MFA pages and go straight to the 'your information' page" do
    it "redirects them back to the first MFA page" do
      visit_registration_form
      enter_email_address
      enter_password
      enter_uk_phone_number
      submit_registration_form
      query = current_url.split("?")[1]
      visit "#{new_user_registration_your_information_path}?#{query}"

      expect(page).to have_text(I18n.t("mfa.phone.code.sign_up_heading"))
    end
  end

  context "MFA is disabled" do
    let(:mfa_enabled) { false }

    it "skips over the MFA screens" do
      visit_registration_form
      enter_email_address
      enter_password
      submit_registration_form
      provide_consent

      expect(page).to have_text(I18n.t("confirmation_sent.heading"))

      expect(User.last).to_not be_nil
      expect(User.last.email).to eq(email)
      expect(User.last.phone).to be_nil
    end
  end

  context "registrations are disabled" do
    let(:registration_enabled) { false }

    it "shows an error message" do
      visit_registration_form

      expect(page).to have_text(I18n.t("devise.registrations.closed.heading"))
    end
  end

  def user_is_returned_to_registration_start
    expect(page).to have_text(I18n.t("devise.registrations.start.heading"))
  end

  def visit_registration_form
    visit new_user_registration_start_path
  end

  def visit_user_account_dashboard
    visit user_root_path
  end

  def click_on_security
    click_on I18n.t("navigation.menu_bar.security.link_text")
  end

  def i_see_an_account_created_event
    expect(page).to have_content I18n.t("account.security.event.user_created")
  end

  def submit_registration_form
    click_on I18n.t("devise.registrations.start.fields.submit.label")
  end

  def enter_email_address
    fill_in "email", with: email
  end

  def enter_password
    fill_in "password", with: password
  end

  def enter_phone_number(number)
    fill_in "phone", with: number
  end

  def enter_uk_phone_number
    enter_phone_number(phone_number)
  end

  def enter_non_mobile_phone_number
    enter_phone_number("01234567890")
  end

  def enter_invalid_phone_number
    enter_phone_number("999")
  end

  def enter_international_phone_number
    enter_phone_number("+15417543010")
  end

  def enter_international_phone_number_without_plus
    enter_phone_number("0015417543010")
  end

  def enter_mfa
    phone_code = RegistrationState.order(:updated_at).last.phone_code
    fill_in "phone_code", with: phone_code
    click_on I18n.t("mfa.phone.code.fields.submit.label")
  end

  def enter_incorrect_mfa
    phone_code = RegistrationState.order(:updated_at).last.phone_code
    fill_in "phone_code", with: "1#{phone_code}"
    click_on I18n.t("mfa.phone.code.fields.submit.label")
  end

  def request_new_mfa_code
    click_on "send a new security code"
    click_on I18n.t("mfa.phone.resend.fields.submit.label")
  end

  def provide_consent
    find(:css, "input[name='cookie_consent'][value='yes']").set(true)
    find(:css, "input[name='feedback_consent'][value='no']").set(true)
    click_on I18n.t("devise.registrations.your_information.fields.submit.label")
  end
end
