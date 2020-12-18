require "gds_api/test_helpers/email_alert_api"

RSpec.describe ActivateEmailSubscriptionsJob do
  include GdsApi::TestHelpers::EmailAlertApi

  let(:user) { FactoryBot.create(:user, :confirmed) }

  context "the user has an email subscription" do
    let!(:subscription) { FactoryBot.create(:email_subscription, user_id: user.id, subscription_id: nil) }

    it "calls email-alert-api to create the subscription" do
      stub_subscriber_list = stub_email_alert_api_has_subscriber_list_by_slug(slug: subscription.topic_slug, returned_attributes: { id: "list-id" })

      stub_activate = stub_email_alert_api_creates_a_subscription(
        subscriber_list_id: "list-id",
        address: user.email,
        frequency: "daily",
        returned_subscription_id: "subscription-id",
        skip_confirmation_email: true,
      )

      described_class.perform_now user.id

      expect(user.reload.email_subscriptions&.first&.subscription_id).to_not be_nil
      expect(stub_subscriber_list).to have_been_made
      expect(stub_activate).to have_been_made
    end

    context "the email subscription is already active" do
      before { subscription.update!(subscription_id: "an-old-subscription") }

      it "recreates the subscription" do
        stub_subscriber_list = stub_email_alert_api_has_subscriber_list_by_slug(slug: subscription.topic_slug, returned_attributes: { id: "list-id" })
        stub_deactivate = stub_email_alert_api_unsubscribes_a_subscription(subscription.subscription_id)

        stub_activate = stub_email_alert_api_creates_a_subscription(
          subscriber_list_id: "list-id",
          address: user.email,
          frequency: "daily",
          returned_subscription_id: "subscription-id",
          skip_confirmation_email: true,
        )

        described_class.perform_now user.id

        expect(user.reload.email_subscriptions&.first&.subscription_id).to_not be_nil
        expect(stub_subscriber_list).to have_been_made
        expect(stub_activate).to have_been_made
        expect(stub_deactivate).to have_been_made
      end
    end
  end
end
