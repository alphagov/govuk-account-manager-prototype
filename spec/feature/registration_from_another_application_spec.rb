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

  let(:email) { "email@example.com" }
  let(:password) { "abcd1234" }

  it "shows the registration form" do
    i_click_from_application

    expect(page).to have_text("If you already have an account")
  end

  context "when the feature_flag_enforce_levels_of_authentication is 'enabled'" do
    before do
      allow(Rails.configuration).to receive(:feature_flag_enforce_levels_of_authentication).and_return(true)
    end

    context "arriving from a level0 application" do
      let(:application_scopes) { %i[openid level0 test_scope_read test_scope_write] }

      it "completes the signup journey without MFA and stores :level_of_authentication level0" do
        i_click_from_application
        i_enter_registration_details_without_phone
        i_consent_my_information_being_used

        expect(page).to have_text(I18n.t("confirmation_sent.heading"))
        expect(return_to_app_url(page)).to include("scope=openid+level0")
      end
    end

    context "arriving from a level1 application" do
      let(:application_scopes) { %i[openid level1 test_scope_read test_scope_write] }

      it "completes the signup journey with MFA and stores :level_of_authentication level1" do
        i_click_from_application
        i_enter_registration_details
        i_enter_phone_code
        i_consent_my_information_being_used

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

  def i_click_from_application
    visit authorization_endpoint_url(client: application, scope: application_scopes.join(" "), register: "1")
  end

  def i_enter_registration_details
    fill_in "email", with: email
    fill_in "password", with: password
    fill_in "phone", with: "07958123456"
    click_on I18n.t("devise.registrations.start.fields.submit.label")
  end

  def i_enter_registration_details_without_phone
    fill_in "email", with: email
    fill_in "password", with: password
    click_on I18n.t("devise.registrations.start.fields.submit.label")
  end

  def i_enter_phone_code
    phone_code = RegistrationState.order(:updated_at).last.phone_code
    fill_in "phone_code", with: phone_code
    click_on I18n.t("mfa.phone.code.fields.submit.label")
  end

  def i_consent_my_information_being_used
    find(:css, "input[name='cookie_consent'][value='yes']").set(true)
    find(:css, "input[name='feedback_consent'][value='yes']").set(true)
    click_on I18n.t("devise.registrations.your_information.fields.submit.label")
  end
end
