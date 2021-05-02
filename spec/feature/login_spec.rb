RSpec.feature "Logging in" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

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

  context "when the user doesn't have MFA set up" do
    let(:user) { FactoryBot.create(:user, :without_mfa) }

    it "bypasses the MFA page" do
      enter_email_address_and_password

      expect(page).to have_text(I18n.t("account.your_account.heading"))
    end

    it "allows the user to change email address" do
      enter_email_address_and_password
      visit_change_email_page
      expect(page).to have_text(I18n.t("devise.registrations.edit.heading_email"))
    end
  end

  context "when the email is missing" do
    it "shows an error" do
      enter_email_address_and_password(email: "")

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.blank"))
    end
  end

  context "when the email is invalid" do
    it "shows an error" do
      enter_email_address_and_password(email: "not-a-real-email-address")

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.invalid"))
    end
  end

  context "the password is missing" do
    it "returns an error" do
      enter_email_address_and_password(password: "")

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
      user_is_returned_to_login_screen
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
    it "returns an error" do
      enter_email_address_and_password(email: "no-account@digital.cabinet-office.gov.uk")

      expect(page).to have_text(I18n.t("devise.failure.no_account"))
    end

    context "warn_about_transition_checker_when_logging_in_to_a_missing_account is set" do
      before { allow(Rails.configuration).to receive(:warn_about_transition_checker_when_logging_in_to_a_missing_account).and_return(true) }

      it "tells the user to visit the transition checker" do
        enter_email_address_and_password(email: "no-account@digital.cabinet-office.gov.uk")

        expect(page).to have_text(Rails::Html::FullSanitizer.new.sanitize(I18n.t("devise.registrations.transition_checker.message")))
      end
    end
  end
  context "logging in from an OAuth journey" do
    let(:application) do
      FactoryBot.create(
        :oauth_application,
        name: "Some Other Government Service",
        redirect_uri: "https://www.gov.uk",
        scopes: %i[openid level0 level1],
      )
    end

    context "when the feature_flag_enforce_levels_of_authentication is not 'enabled'" do
      before do
        expect(user.ephemeral_states.last).to be_nil
        log_in
      end

      it "records that the user has logged in with level-of-authentication 1" do
        enter_mfa

        expect(user.reload.ephemeral_states.last&.level_of_authentication).to eq("level1")
      end

      context "when the user doesn't have MFA set up" do
        let(:user) { FactoryBot.create(:user, :without_mfa) }

        it "records that the user has logged in with level-of-authentication 0" do
          expect(user.reload.ephemeral_states.last&.level_of_authentication).to eq("level0")
        end
      end
    end

    context "when the feature_flag_enforce_levels_of_authentication is 'enabled'" do
      before { allow(Rails.configuration).to receive(:feature_flag_enforce_levels_of_authentication).and_return(true) }

      context "when the user doesn't have MFA set up" do
        let(:user) { FactoryBot.create(:user, :without_mfa) }

        before { log_in(%w[level0]) }

        it "does not redirect to do MFA if level0 is requested" do
          visit authorization_endpoint_url(client: application, scope: "openid level0")
          expect(page.current_url).to start_with("https://www.gov.uk/")
        end

        it "raises NotImplementedError if a higher scope is requested" do
          expect {
            visit authorization_endpoint_url(client: application, scope: "openid level10")
          }.to raise_error(NotImplementedError)
        end

        it "raises NotImplementedError if no scope is requested" do
          expect {
            visit authorization_endpoint_url(client: application, scope: "openid")
          }.to raise_error(NotImplementedError)
        end
      end

      context "for a level0 authorised user" do
        before { log_in(%w[level0]) }

        it "does not redirect to do MFA if level0 is requested" do
          visit authorization_endpoint_url(client: application, scope: "openid level0")
          expect(page).to_not have_content(I18n.t("mfa.phone.code.sign_in_heading"))
        end

        it "redirects to do MFA if a higher scope is requested" do
          visit authorization_endpoint_url(client: application, scope: "openid level10")
          expect(page).to have_content(I18n.t("mfa.phone.code.sign_in_heading"))
        end

        it "redirects to do MFA if no scope is requested" do
          visit authorization_endpoint_url(client: application, scope: "openid")
          expect(page).to have_content(I18n.t("mfa.phone.code.sign_in_heading"))
        end
      end

      context "for a level1 authorised user" do
        before do
          log_in(%w[level1])
          enter_mfa
        end

        it "sucessfully returns the current user if the level of authentication meets the requirement" do
          visit authorization_endpoint_url(client: application, scope: "openid level1")

          expect(page.current_url).to start_with("https://www.gov.uk/")
        end
      end
    end
  end

  def log_in(extra_scopes = [])
    visit authorization_endpoint_url(client: application, scope: ["openid", *extra_scopes].join(" "))
    user_is_returned_to_login_screen

    fill_in "email", with: user.email
    fill_in "password", with: user.password
    click_on I18n.t("devise.sessions.new.fields.submit.label")
  end

  def user_is_returned_to_login_screen
    expect(page).to have_text(I18n.t("devise.sessions.new.heading"))
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

  def visit_change_email_page
    within ".accounts-menu" do
      click_on "Manage your account"
    end
    within "#main-content" do
      click_on "Change Email"
    end
  end
end
