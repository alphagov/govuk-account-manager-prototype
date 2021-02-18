require "spec_helper"

RSpec.describe "/oauth/authorize" do
  let(:user) { FactoryBot.create(:user) }

  let(:application) do
    FactoryBot.create(
      :oauth_application,
      name: "Some Other Government Service",
      redirect_uri: "https://www.gov.uk",
      scopes: %i[openid email transition_checker],
    )
  end

  context "the state param is a JWT ID" do
    let(:payload) do
      {
        scopes: [],
        attributes: {},
        post_register_oauth: "#{Rails.application.config.redirect_base_url}/oauth/authorize?some-query-string",
      }
    end

    let(:jwt) { Jwt.create!(jwt_payload: JWT.encode(payload, nil, "none"), application_id_from_token: application.id) }

    it "redirects to the registration page & fetches the JWT" do
      get authorization_endpoint_url(client: application, scope: "openid email transition_checker", state: jwt.id)
      expect(response.redirect_url).to include(new_user_registration_start_path)

      get response.redirect_url

      expect { post new_user_registration_start_path, params: { "user[email]" => "email@example.com", "user[password]" => "abcd1234", "user[phone]" => "+447958123456" } }.to(change { RegistrationState.count })
      expect(RegistrationState.last.previous_url).to eq(payload[:post_register_oauth].delete_prefix(Rails.application.config.redirect_base_url))
    end

    it "fetches the JWT if the user then goes to the login page" do
      user = FactoryBot.create(:user)

      get authorization_endpoint_url(client: application, scope: "openid email transition_checker", state: jwt.id)

      previous_url = CGI.parse(response.redirect_url.split("?")[1])["previous_url"][0]
      expect { post new_user_session_path, params: { previous_url: previous_url, "user[email]" => user.email, "user[password]" => user.password } }.to(change { LoginState.count })
      expect(LoginState.last.redirect_path).to eq(previous_url)
    end
  end

  context "with a user logged in" do
    before { sign_in user }

    it "asks for authorization to access the email address" do
      get authorization_endpoint_url(client: application, scope: "openid email transition_checker")

      expect(response.body).to have_content(I18n.t("doorkeeper.scopes.email"))
    end

    it "does not ask for authorization to access transition checker state" do
      get authorization_endpoint_url(client: application, scope: "openid email transition_checker")

      expect(response.body).not_to have_content(I18n.t("doorkeeper.scopes.transition_checker"))
    end

    it "does not ask for authorization to login" do
      get authorization_endpoint_url(client: application, scope: "openid email transition_checker")

      expect(response.body).not_to have_content(I18n.t("doorkeeper.scopes.openid"))
    end

    it "does not ask for authorization to login and redirects to application when no other permissions needed" do
      get authorization_endpoint_url(client: application, scope: "openid")

      expect(response.redirect_url).not_to be_nil
    end

    it "does not ask for authorization to login and redirects to application when only hidden needed" do
      get authorization_endpoint_url(client: application, scope: "openid transition_checker")

      expect(response.redirect_url).not_to be_nil
    end

    it "records the _ga parameter" do
      get authorization_endpoint_url(client: application, scope: "openid transition_checker", _ga: "foo")

      expect(EphemeralState.last).to_not be_nil
      expect(EphemeralState.last.ga_client_id).to eq("foo")
    end
  end
end
