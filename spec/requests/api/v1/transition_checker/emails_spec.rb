require "gds_api/test_helpers/email_alert_api"

RSpec.describe "/api/v1/transition-checker/*" do
  include GdsApi::TestHelpers::EmailAlertApi

  let(:user) { FactoryBot.create(:user) }

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

  context "GET /email-subscription" do
    context "with a email subscription" do
      let!(:subscription) { FactoryBot.create(:email_subscription, user_id: user.id) }

      let(:email_alert_api_subscription_ended) { false }

      before do
        stub_email_alert_api_has_subscription(
          subscription.subscription_id,
          "daily",
          ended: email_alert_api_subscription_ended,
        )
      end

      it "returns a 204" do
        get api_v1_transition_checker_email_subscription_path, headers: headers
        expect(response).to have_http_status(204)
      end

      context "the subscription is disabled" do
        let(:email_alert_api_subscription_ended) { true }

        it "returns a 410" do
          get api_v1_transition_checker_email_subscription_path, headers: headers
          expect(response).to have_http_status(410)
        end
      end

      context "the subscription hasn't been activated" do
        before { subscription.update!(subscription_id: nil) }

        it "returns a 204" do
          get api_v1_transition_checker_email_subscription_path, headers: headers
          expect(response).to have_http_status(204)
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

  context "POST /email-subscription" do
    let(:params) { { topic_slug: new_topic_slug } }
    let(:new_topic_slug) { "new-topic-slug" }

    context "the user has confirmed their email address" do
      let(:user) { FactoryBot.create(:confirmed_user) }

      context "with an email subscription" do
        let(:subscription) { FactoryBot.create(:email_subscription, user_id: user.id) }

        before do
          stub_email_alert_api_has_subscription(
            subscription.subscription_id,
            "daily",
          )
        end

        it "deactivates the old subscription and activates the new subscription" do
          stub_subscriber_list = stub_email_alert_api_has_subscriber_list_by_slug(slug: new_topic_slug, returned_attributes: { id: "list-id" })
          stub_activate = stub_email_alert_api_creates_a_subscription("list-id", user.email, "daily", "subscription-id")
          stub_deactivate = stub_email_alert_api_unsubscribes_a_subscription(subscription.subscription_id)
          post api_v1_transition_checker_email_subscription_path, headers: headers, params: params
          expect(user.reload.email_subscriptions&.first&.topic_slug).to eq(new_topic_slug)
          expect(stub_subscriber_list).to have_been_made
          expect(stub_activate).to have_been_made
          expect(stub_deactivate).to have_been_made
        end
      end

      context "without an email subscription" do
        it "activates the new subscription" do
          stub_subscriber_list = stub_email_alert_api_has_subscriber_list_by_slug(slug: new_topic_slug, returned_attributes: { id: "list-id" })
          stub_activate = stub_email_alert_api_creates_a_subscription("list-id", user.email, "daily", "subscription-id")
          post api_v1_transition_checker_email_subscription_path, headers: headers, params: params
          expect(user.reload.email_subscriptions&.first&.topic_slug).to eq(new_topic_slug)
          expect(stub_subscriber_list).to have_been_made
          expect(stub_activate).to have_been_made
        end
      end
    end

    context "the user has not confirmed their email address" do
      it "does not activate the new subscription" do
        post api_v1_transition_checker_email_subscription_path, headers: headers, params: params
        expect(user.reload.email_subscriptions&.first&.topic_slug).to eq(new_topic_slug)
      end
    end
  end
end
