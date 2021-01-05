RSpec.feature "Logging in" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  before { allow(Rails.configuration).to receive(:feature_flag_mfa).and_return(mfa_enabled) }

  let(:mfa_enabled) { true }

  let!(:user) { FactoryBot.create(:user) }

  it "logs the user in" do
    enter_email_address_and_password
    enter_mfa

    expect(page).to have_text(I18n.t("account.your_account.heading"))
  end

  it "shows the MFA page" do
    enter_email_address_and_password

    expect(page).to have_text(I18n.t("mfa.phone.code.fields.phone_code.label"))
  end

  it "shows the login event on the security page" do
    enter_email_address_and_password
    enter_mfa
    visit_security_page

    expect(page).to have_text(I18n.t("account.security.event.login_success"))
  end

  context "when the email is missing" do
    it "shows an error" do
      enter_email_address_and_password(email: "")

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.blank"))
    end
  end

  context "the password is missing" do
    it "returns an error" do
      enter_email_address_and_password(password: "") # pragma: allowlist secret

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.password.blank"))
    end
  end

  context "the password is incorrect" do
    it "shows an error but does not lock the account on the first 4 entries" do
      4.times do
        enter_email_address_and_password(password: "1234")

        expect(page).to_not have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("devise.failure.last_attempt")))
        expect(page).to_not have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("devise.failure.locked")))
        expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("devise.failure.invalid")))
        expect(User.last.access_locked?).to be false
      end
    end

    it "shows a warning on the 5th entry" do
      5.times do
        enter_email_address_and_password(password: "1234")
      end

      expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("devise.failure.last_attempt")))
      expect(page).to_not have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("devise.failure.locked")))
      expect(User.last.access_locked?).to be false
    end

    it "locks the account on the 6th entry" do
      6.times do
        enter_email_address_and_password(password: "1234")
      end

      expect(page).to_not have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("devise.failure.last_attempt")))
      expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("devise.failure.locked")))
      expect(User.last.access_locked?).to be true
    end
  end

  context "the user tries to bypass MFA" do
    it "does not log them in" do
      enter_email_address_and_password
      go_straight_to_account_page

      expect(page).to_not have_text(I18n.t("account.your_account.heading"))
    end
  end

  context "the MFA code is incorrect" do
    it "returns an error" do
      enter_email_address_and_password
      enter_incorrect_mfa

      expect(page).to have_text(I18n.t("mfa.errors.phone_code.invalid"))
    end

    context "the user keeps entering an incorrect code" do
      it "expires the code" do
        enter_email_address_and_password
        (MultiFactorAuth::ALLOWED_ATTEMPTS + 1).times { enter_incorrect_mfa }

        expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("mfa.errors.phone_code.too_many_attempts")))
      end

      it "lets the user request a new code" do
        enter_email_address_and_password
        (MultiFactorAuth::ALLOWED_ATTEMPTS + 1).times { enter_incorrect_mfa }
        request_new_mfa_code
        enter_mfa

        expect(page).to have_text(I18n.t("account.your_account.heading"))
      end
    end
  end

  context "the MFA code is too old" do
    it "expires the code" do
      enter_email_address_and_password
      travel(MultiFactorAuth::EXPIRATION_AGE + 1.second)
      enter_mfa

      expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("mfa.errors.phone_code.expired")))
    end
  end

  context "MFA is disabled" do
    let(:mfa_enabled) { false }

    it "skips over the MFA screen" do
      enter_email_address_and_password

      expect(page).to have_text(I18n.t("account.your_account.heading"))
    end
  end

  context "user has not confirmed email address" do
    it "allows login when confirmation was sent less than 7 days ago" do
      user.update!(confirmation_sent_at: Time.zone.now - 6.days)

      enter_email_address_and_password
      enter_mfa

      expect(page).to have_text(I18n.t("account.your_account.heading"))
    end

    it "shows an error when confirmation was sent more than 7 days ago" do
      user.update!(confirmation_sent_at: Time.zone.now - 7.days)

      enter_email_address_and_password

      expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("devise.failure.unconfirmed")))
    end
  end

  context "when the account does not exist" do
    context "if user comes from the transition checker" do
      it "redirects to registration form" do
        Capybara.current_session.driver.submit :post, welcome_path, {
          "jwt" => "some_data",
        }.compact

        enter_email_address_and_password(email: "no-account@digital.cabinet-office.gov.uk")

        expect(page).to have_text(I18n.t("devise.failure.no_account"))
      end
    end

    context "if user does not come from the transition checker and force_jwt_at_registration is set" do
      before { allow(Rails.configuration).to receive(:force_jwt_at_registration).and_return(true) }

      it "redirects to an informational page" do
        enter_email_address_and_password(email: "no-account@digital.cabinet-office.gov.uk")

        expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("devise.registrations.transition_checker.message")))
      end
    end

    context "if user does not come from the transition checker and force_jwt_at_registration is not set" do
      it "returns an error" do
        enter_email_address_and_password(email: "no-account@digital.cabinet-office.gov.uk")

        expect(page).to have_text(I18n.t("devise.failure.no_account"))
      end
    end
  end

  def enter_email_address_and_password(email: user.email, password: user.password)
    visit new_user_session_path
    fill_in "email", with: email
    fill_in "password", with: password
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

  def request_new_mfa_code
    click_on "send a new security code"
    click_on I18n.t("mfa.phone.resend.fields.submit.label")
  end

  def go_straight_to_account_page
    visit user_root_path
  end

  def visit_security_page
    click_on I18n.t("navigation.menu_bar.security.link_text")
  end
end
