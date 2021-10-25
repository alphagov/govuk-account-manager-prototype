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

  let(:application2) do
    FactoryBot.create(
      :oauth_application,
      name: "Yet Other Government Service",
      redirect_uri: "https://www.gov.uk",
      scopes: %i[openid email transition_checker],
    )
  end

  context "with a user logged in" do
    before { sign_in user }

    it "lists how and when data was used" do
      DataActivity.create!(
        user_id: user.id,
        scopes: "openid email transition_checker",
        token: "",
        oauth_application_id: application.id,
      )

      get account_security_path

      expect(response.body).to have_content(application.name)
    end

    it "does not list transition checker data usage" do
      get account_security_path(client: application, scope: "openid email transition_checker")

      expect(response.body).not_to have_content(I18n.t("account.data_exchange.scope.transition_checker"))
    end

    it "shows only the latest exchange for each service" do
      DataActivity.create!(user_id: user.id, scopes: "", token: "", oauth_application_id: application.id, created_at: Time.zone.local(2018, 1, 1, 0, 0, 0))
      DataActivity.create!(user_id: user.id, scopes: "", token: "", oauth_application_id: application2.id, created_at: Time.zone.local(2019, 1, 1, 0, 0, 0))
      DataActivity.create!(user_id: user.id, scopes: "", token: "", oauth_application_id: application.id, created_at: Time.zone.local(2020, 1, 1, 0, 0, 0))
      DataActivity.create!(user_id: user.id, scopes: "", token: "", oauth_application_id: application2.id, created_at: Time.zone.local(2021, 1, 1, 0, 0, 0))

      get account_security_path

      expect(response.body).to_not have_content("2018")
      expect(response.body).to_not have_content("2019")
      expect(response.body).to have_content("2020")
      expect(response.body).to have_content("2021")
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
