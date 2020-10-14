require "gds_api/test_helpers/email_alert_api"

RSpec.describe ActivateEmailSubscriptionsJob, type: :job do
  include GdsApi::TestHelpers::EmailAlertApi

  let(:user) do
    FactoryBot.create(
      :user,
      email: "user@domain.tld",
      password: "breadbread1", # pragma: allowlist secret
      password_confirmation: "breadbread1",
      confirmed_at: Time.zone.now,
    )
  end

  context "the user has an email subscription" do
    let!(:subscription) do
      FactoryBot.create(
        :email_subscription,
        user_id: user.id,
        topic_slug: "emails",
      )
    end

    it "calls email-alert-api to create the subscription" do
      stub_subscriber_list = stub_email_alert_api_has_subscriber_list_by_slug(slug: subscription.topic_slug, returned_attributes: { id: "list-id" })
      stub_activate = stub_email_alert_api_creates_a_subscription("list-id", user.email, "daily", "subscription-id")

      described_class.perform_now user.id

      expect(user.reload.email_subscriptions&.first&.subscription_id).to_not be_nil
      expect(stub_subscriber_list).to have_been_made
      expect(stub_activate).to have_been_made
    end
  end
end
