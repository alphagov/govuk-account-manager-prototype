require "spec_helper"

RSpec.feature "/account/your-data" do
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
    before do
      log_in(user.email, user.password)
    end

    it "lists how and when data was used" do
      visit account_security_path(client: application, scope: "openid email")

      expect(page).to have_text(application.name)
      expect(page).to have_text("used #{I18n.t('account.data_exchange.scope.email')}")
    end

    it "does not list transition checker data usage" do
      visit account_security_path(client: application, scope: "openid email transition_checker")

      expect(page).not_to have_text(I18n.t("account.data_exchange.scope.transition_checker"))
    end
  end
end
