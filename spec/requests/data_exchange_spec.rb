require "spec_helper"

RSpec.describe "/account/security" do
  let(:user) { FactoryBot.create(:user) }

  let(:application) do
    FactoryBot.create(
      :oauth_application,
      name: "Some Other Government Service",
      redirect_uri: "https://www.gov.uk",
      scopes: %i[openid email transition_checker],
    )
  end

  let(:token) do
    FactoryBot.create(
      :oauth_access_token,
      resource_owner_id: user.id,
      application_id: application.id,
      scopes: application.scopes,
    )
  end

  let!(:activity) do
    FactoryBot.create(
      :data_activity,
      user_id: user.id,
      oauth_application_id: application.id,
      created_at: Time.zone.now,
      scopes: "openid email transition_checker",
      token: token.token,
    )
  end

  context "with a user logged in" do
    before { sign_in user }

    it "lists how and when data was used" do
      get account_security_path(client: application, scope: "openid email")

      expect(response.body).to have_content(application.name)
      expect(response.body).to have_content(I18n.t("account.data_exchange.scope.email"))
    end

    it "does not list transition checker data usage" do
      get account_security_path(client: application, scope: "openid email transition_checker")

      expect(response.body).not_to have_content(I18n.t("account.data_exchange.scope.transition_checker"))
    end

    it "fills in missing countries for security activities" do
      activity = SecurityActivity.create!(
        event_type: SecurityActivity::LOGIN_SUCCESS.id,
        user_id: user.id,
        ip_address: "1.1.1.1",
      )

      stub_request(:get, "http://ipinfo.io/#{activity.ip_address}/geo").to_return(
        status: 200,
        body: {
          ip: activity.ip_address,
          country: "Narnia",
        }.to_json,
      )

      get account_security_path

      expect(activity.reload.ip_address_country).to eq("Narnia")
    end
  end
end
