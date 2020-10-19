require "spec_helper"

RSpec.feature "/oauth/authorize" do
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
    before do
      log_in(user.email, user.password)
    end

    it "asks for authorization to access listed scopes" do
      visit authorization_endpoint_url(client: application, scope: "openid email")

      expect(page).not_to have_current_path(application.redirect_uri, ignore_query: true)
      expect(page).to have_text(I18n.t("doorkeeper.scopes.email"))
    end

    it "does not ask for authorization to access transition checker state" do
      visit authorization_endpoint_url(client: application, scope: "openid email transition_checker")

      expect(page).not_to have_current_path(application.redirect_uri, ignore_query: true)
      expect(page).not_to have_text(I18n.t("doorkeeper.scopes.transition_checker"))
    end

    it "does not ask for authorization to login" do
      visit authorization_endpoint_url(client: application, scope: "openid email transition_checker")

      expect(page).not_to have_current_path(application.redirect_uri, ignore_query: true)
      expect(page).not_to have_text(I18n.t("doorkeeper.scopes.openid"))
    end

    it "does not ask for authorization to login and redirects to application when no other permissions needed" do
      visit authorization_endpoint_url(client: application, scope: "openid")

      expect(page).to have_current_path(application.redirect_uri, ignore_query: true)
    end

    it "does not ask for authorization to login and redirects to application when only hidden needed" do
      visit authorization_endpoint_url(client: application, scope: "openid transition_checker")

      expect(page).to have_current_path(application.redirect_uri, ignore_query: true)
    end
  end
end
