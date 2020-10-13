require "gds_api/test_helpers/email_alert_api"

RSpec.describe User, type: :unit do
  include GdsApi::TestHelpers::EmailAlertApi

  let(:attribute_service_url) { "https://attribute-service" }

  let(:user) do
    FactoryBot.create(
      :user,
      email: "user@domain.tld",
      password: "breadbread1", # pragma: allowlist secret
      password_confirmation: "breadbread1",
    )
  end

  let(:bearer_token) { AccountManagerApplication.user_token(user.id).token }

  before do
    ENV["ATTRIBUTE_SERVICE_URL"] = attribute_service_url
  end

  after do
    ENV["ATTRIBUTE_SERVICE_URL"] = nil
  end

  context "#destroy!" do
    it "calls the attribute service to delete the attributes" do
      attribute_service_stub = stub_attribute_service_delete_all
      user.destroy!
      expect(attribute_service_stub).to have_been_made
    end

    context "there is an email subscription" do
      let!(:subscription) do
        FactoryBot.create(
          :email_subscription,
          user_id: user.id,
          topic_slug: "transition checker emails",
          subscription_id: "subscription-id",
        )
      end

      it "calls email-alert-api to deactivate the subscription" do
        stub_attribute_service_delete_all
        email_alert_api_stub = stub_email_alert_api_unsubscribes_a_subscription(subscription.subscription_id)
        user.destroy!
        expect(email_alert_api_stub).to have_been_made
      end
    end

    def stub_attribute_service_delete_all
      stub_request(:delete, "#{attribute_service_url}/v1/attributes/all")
        .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
        .to_return(status: 200)
    end
  end
end
