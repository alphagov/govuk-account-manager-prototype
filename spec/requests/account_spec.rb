require "spec_helper"

RSpec.feature "/account" do
  let!(:application) do
    FactoryBot.create(
      :oauth_application,
      name: "Transition Checker",
      redirect_uri: "https://www.gov.uk/transition-checker/login/callback",
      scopes: [],
    )
  end

  let(:user) do
    FactoryBot.create(
      :user,
      email: "somebody@example.com",
      password: "breadbread1",
      password_confirmation: "breadbread1",
    )
  end

  let(:userinfo) { {} }

  before do
    log_in(user.email, user.password)

    ENV["ATTRIBUTE_SERVICE_URL"] = "http://attribute-service"
    stub_request(:get, "http://attribute-service/oidc/user_info").to_return(body: userinfo.to_json)
  end

  after do
    ENV["ATTRIBUTE_SERVICE_URL"] = nil
  end

  context "with transition checker state" do
    let(:userinfo) { { transition_checker_state: { timestamp: 42 } } }

    it "shows the service card" do
      visit user_root_path

      expect(page).to have_text(I18n.t("service_card.transition_checker.heading"))
      expect(page).to have_text(I18n.t("service_card.transition_checker.results_link"))
      expect(page).to have_text(I18n.t("service_card.transition_checker.update_link"))
      expect(page).to have_text(I18n.t("service_card.transition_checker.notifications_link"))
    end
  end
end
