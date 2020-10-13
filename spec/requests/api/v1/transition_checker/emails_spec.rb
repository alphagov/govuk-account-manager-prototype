require "gds_api/test_helpers/email_alert_api"

RSpec.describe "/api/v1/transition-checker/*" do
  include GdsApi::TestHelpers::EmailAlertApi

  let(:user) do
    FactoryBot.create(
      :user,
      email: "user@domain.tld",
      password: "breadbread1", # pragma: allowlist secret
      password_confirmation: "breadbread1",
    )
  end

  let(:application) do
    FactoryBot.create(
      :oauth_application,
      name: "Transition Checker",
      redirect_uri: "https://www.gov.uk/transition-checker/login/callback",
      scopes: %i[transition_checker openid],
    )
  end

  let(:bearer_token) do
    FactoryBot.create(
      :oauth_access_token,
      resource_owner_id: user.id,
      application_id: application.id,
      scopes: %i[transition_checker],
    )
  end

  let(:headers) do
    {
      Authorization: "Bearer #{bearer_token.token}",
    }
  end

  context "/check-email-subscription" do
    context "with a email subscription" do
      let!(:subscription) do
        FactoryBot.create(
          :email_subscription,
          user_id: user.id,
          topic_slug: "transition checker emails",
          subscription_id: email_alert_api_subscription_id,
        )
      end

      let(:email_alert_api_subscription_id) { "some-id" }
      let(:email_alert_api_subscription_ended) { false }

      before do
        stub_email_alert_api_has_subscription(
          email_alert_api_subscription_id,
          "daily",
          ended: email_alert_api_subscription_ended,
        )
      end

      it "returns a 200" do
        get api_v1_transition_checker_email_subscription_path, headers: headers
        expect(response).to have_http_status(200)
      end

      context "the subscription is disabled" do
        let(:email_alert_api_subscription_ended) { true }

        it "returns a 410" do
          get api_v1_transition_checker_email_subscription_path, headers: headers
          expect(response).to have_http_status(410)
        end
      end

      context "the subscription hasn't been activated" do
        let(:email_alert_api_subscription_id) { nil }

        it "returns a 200" do
          get api_v1_transition_checker_email_subscription_path, headers: headers
          expect(response).to have_http_status(200)
        end
      end
    end

    context "without an email subscription" do
      it "returns a 404" do
        get api_v1_transition_checker_email_subscription_path, headers: headers
        expect(response).to have_http_status(404)
      end
    end
  end
end
