RSpec.describe AccountHelper, type: :helper do
  describe "#finder_frontend_base_uri" do
    let!(:application) do
      FactoryBot.create(
        :oauth_application,
        name: "Transition Checker",
        redirect_uri: "https://www.gov.uk/transition-checker/login/callback",
        scopes: [],
      )
    end

    it "returns https://www.gov.uk" do
      expect(finder_frontend_base_uri).to eq("https://www.gov.uk")
    end
  end

  describe "#email_alert_frontend_frontend_base_uri" do
    context "running in production" do
      let!(:application) do
        FactoryBot.create(
          :oauth_application,
          name: "Transition Checker",
          redirect_uri: "https://www.gov.uk/transition-checker/login/callback",
          scopes: [],
        )
      end

      it "returns https://www.gov.uk" do
        expect(email_alert_frontend_base_uri).to eq("https://www.gov.uk")
      end
    end

    context "running in development" do
      let!(:application) do
        FactoryBot.create(
          :oauth_application,
          name: "Transition Checker",
          redirect_uri: "http://finder-frontend.dev.gov.uk/transition-checker/login/callback",
          scopes: [],
        )
      end

      it "returns http://email-alert-frontend.dev.gov.uk" do
        expect(email_alert_frontend_base_uri).to eq("http://email-alert-frontend.dev.gov.uk")
      end
    end
  end
end
