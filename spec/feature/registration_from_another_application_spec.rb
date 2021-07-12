RSpec.feature "Registration (coming from another application)" do
  include ActiveJob::TestHelper

  let(:application) do
    FactoryBot.create(
      :oauth_application,
      name: "name",
      redirect_uri: "http://localhost",
      scopes: application_scopes,
    )
  end

  let(:application_scopes) { %i[test_scope_read test_scope_write] }

  let(:jwt_attributes) { { test: "value" } }

  let(:jwt) do
    Jwt.create!(jwt_payload: JWT.encode({ attributes: jwt_attributes }, nil, "none"), application_id_from_token: application.id)
  end

  let(:email) { "email@example.com" }
  let(:password) { "abcd1234" }

  it "creates an access token" do
    start_journey

    token = Doorkeeper::AccessToken.last
    expect(token).to_not be_nil
    expect(token.resource_owner_id).to eq(User.last.id)
    expect(token.expires_in).to eq(Doorkeeper.config.access_token_expires_in)
    expect(token.scopes).to eq(application.scopes)
  end

  it "updates the attributes" do
    start_journey

    assert_enqueued_jobs 1, only: SetAttributesJob
  end

  context "there's an email topic" do
    let(:application_scopes) { %i[transition_checker] }
    let(:jwt_attributes) { { transition_checker_state: { email_topic_slug: email_topic_slug } } }
    let(:email_topic_slug) { "foo" }

    it "asks if the user would like email notifications" do
      start_journey

      expect(page).to have_text(I18n.t("devise.registrations.transition_emails.unsubscribe"))
      expect(page).to_not have_text(I18n.t("activerecord.errors.models.user.attributes.email_decision.invalid"))
    end

    context "the user does want notifications" do
      it "shows the post-registration page" do
        start_journey
        i_want_emails

        expect(page).to_not have_text(I18n.t("devise.registrations.transition_emails.unsubscribe"))
      end

      it "creates the subscription" do
        start_journey
        i_want_emails

        expect(User.last.email_subscriptions.last&.topic_slug).to eq(email_topic_slug)
      end
    end

    context "the user does not want notifications" do
      it "shows the post-registration page" do
        start_journey
        i_do_not_want_emails

        expect(page).to_not have_text(I18n.t("devise.registrations.transition_emails.unsubscribe"))
      end

      it "does not create the subscription" do
        expect {
          start_journey
          i_do_not_want_emails
        }.to_not(change { EmailSubscription.count })
      end
    end

    context "the user doesn't tick either option for notifications" do
      it "shows an error" do
        start_journey
        click_on I18n.t("devise.registrations.transition_emails.fields.submit.label")

        expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email_decision.invalid"))
      end
    end
  end

  context "if the user auths through the application again" do
    before { start_journey }

    it "doesn't prompt for consent" do
      i_click_from_application
      expect(page).to_not have_content(I18n.t("doorkeeper.authorizations.new.able_to"))
    end
  end

  context "the user goes part way through the registration process then starts again and completes" do
    it "shows the post-registration page" do
      i_click_from_application
      i_enter_registration_details
      visit new_user_registration_start_path
      i_enter_registration_details
      i_enter_phone_code

      expect(page).to have_text(I18n.t("confirmation_sent.heading"))
    end
  end

  context "when the feature_flag_enforce_levels_of_authentication is 'enabled'" do
    before do
      allow(Rails.configuration).to receive(:feature_flag_enforce_levels_of_authentication).and_return(true)
    end

    context "arriving from a level0 application" do
      let(:application_scopes) { %i[openid level0 test_scope_read test_scope_write] }

      it "completes the signup journey without MFA and stores :level_of_authentication level0" do
        i_click_from_application
        register_without_mfa

        expect(page).to have_text(I18n.t("confirmation_sent.heading"))
        expect(return_to_app_url(page)).to include("scope=openid+level0")
      end
    end

    context "arriving from a level1 application" do
      let(:application_scopes) { %i[openid level1 test_scope_read test_scope_write] }

      it "completes the signup journey with MFA and stores :level_of_authentication level1" do
        i_click_from_application
        register_with_mfa

        expect(page).to have_text(I18n.t("confirmation_sent.heading"))
        expect(return_to_app_url(page)).to include("scope=openid+level1")
      end
    end
  end

  def return_to_app_url(page)
    url_input_css_selector = "form[data-module='explicit-cross-domain-links'] > input[type='hidden']"
    html = Nokogiri.parse(page.body)
    html.css(url_input_css_selector).first.attributes["value"].value
  end

  def start_journey
    i_click_from_application
    i_enter_registration_details
    i_enter_phone_code
  end

  def register_without_mfa
    register_without_phone_code
    i_consent_my_information_being_used
  end

  def register_with_mfa
    i_enter_registration_details
    i_enter_phone_code
  end

  def register_without_phone_code
    fill_in "email", with: email
    fill_in "password", with: password
    click_on I18n.t("devise.registrations.start.fields.submit.label")
  end

  def i_click_from_application
    visit authorization_endpoint_url(client: application, scope: application_scopes.join(" "), state: jwt.id)
  end

  def i_enter_registration_details
    fill_in "email", with: email
    fill_in "password", with: password
    fill_in "phone", with: "07958123456"
    click_on I18n.t("devise.registrations.start.fields.submit.label")
  end

  def i_enter_phone_code
    phone_code = RegistrationState.order(:updated_at).last.phone_code
    fill_in "phone_code", with: phone_code
    click_on I18n.t("mfa.phone.code.fields.submit.label")

    i_consent_my_information_being_used
  end

  def i_consent_my_information_being_used
    find(:css, "input[name='cookie_consent'][value='yes']").set(true)
    find(:css, "input[name='feedback_consent'][value='yes']").set(true)
    click_on I18n.t("devise.registrations.your_information.fields.submit.label")
  end

  def i_want_emails
    find_field(I18n.t("devise.registrations.transition_emails.fields.emailsignup.yes")).click
    click_on I18n.t("devise.registrations.transition_emails.fields.submit.label")
  end

  def i_do_not_want_emails
    find_field(I18n.t("devise.registrations.transition_emails.fields.emailsignup.no")).click
    click_on I18n.t("devise.registrations.transition_emails.fields.submit.label")
  end
end
