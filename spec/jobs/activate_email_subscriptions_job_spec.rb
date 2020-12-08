require "gds_api/test_helpers/email_alert_api"

RSpec.describe ActivateEmailSubscriptionsJob do
  include GdsApi::TestHelpers::EmailAlertApi

  let(:user) { FactoryBot.create(:user, :confirmed) }

  # these tests are disabled pending fixing a bug in gds-api-adapters:
  # gds-api-adapters stubs a request which returns a "subscription_id"
  # when a subscription is created, but it should actually return an
  # "id"

  context "the user has an email subscription" do
    let!(:subscription) { FactoryBot.create(:email_subscription, user_id: user.id, subscription_id: nil) }

    xit "calls email-alert-api to create the subscription" do
      stub_subscriber_list = stub_email_alert_api_has_subscriber_list_by_slug(slug: subscription.topic_slug, returned_attributes: { id: "list-id" })
      stub_activate = stub_email_alert_api_creates_a_subscription("list-id", user.email, "daily", "subscription-id")

      described_class.perform_now user.id

      expect(user.reload.email_subscriptions&.first&.subscription_id).to_not be_nil
      expect(stub_subscriber_list).to have_been_made
      expect(stub_activate).to have_been_made
    end

    context "the email subscription is already active" do
      before { subscription.update!(subscription_id: "an-old-subscription") }

      xit "recreates the subscription" do
        stub_subscriber_list = stub_email_alert_api_has_subscriber_list_by_slug(slug: subscription.topic_slug, returned_attributes: { id: "list-id" })
        stub_activate = stub_email_alert_api_creates_a_subscription("list-id", user.email, "daily", "subscription-id")
        stub_deactivate = stub_email_alert_api_unsubscribes_a_subscription(subscription.subscription_id)

        described_class.perform_now user.id

        expect(user.reload.email_subscriptions&.first&.subscription_id).to_not be_nil
        expect(stub_subscriber_list).to have_been_made
        expect(stub_activate).to have_been_made
        expect(stub_deactivate).to have_been_made
      end
    end
  end
end
