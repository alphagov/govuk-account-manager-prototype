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

  it "fetches a JWT from the OAuth state param" do
    private_key = OpenSSL::PKey::EC.new("prime256v1").generate_key
    public_key = OpenSSL::PKey::EC.new private_key

    application_key = ApplicationKey.create!(
      application_uid: application.uid,
      key_id: SecureRandom.uuid,
      pem: public_key.to_pem,
    )

    payload = {
      uid: application.uid,
      key: application_key.key_id,
      scopes: [],
      attributes: {},
      post_login_oauth: "#{Rails.application.config.redirect_base_url}/oauth/authorize?some-query-string",
    }

    jwt = Jwt.create!(jwt_payload: JWT.encode(payload, private_key, "ES256"))

    get authorization_endpoint_url(client: application, scope: "openid email transition_checker", state: jwt.id)
    expect(response.redirect_url).not_to be_nil

    post response.redirect_url, params: { "user[email]" => user.email, "user[password]" => user.password }
    post user_session_phone_verify_path, params: { "phone_code" => user.reload.phone_code }
    expect(response).to redirect_to(payload[:post_login_oauth].delete_prefix(Rails.application.config.redirect_base_url))
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
