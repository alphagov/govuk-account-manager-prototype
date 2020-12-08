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
