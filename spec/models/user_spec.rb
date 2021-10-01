require "gds_api/test_helpers/account_api"

RSpec.describe User do
  include GdsApi::TestHelpers::AccountApi

  let(:attribute_service_url) { "https://attribute-service" }
  let(:account_api_url) { "https://account-api" }

  let(:user) { FactoryBot.create(:user) }

  let(:bearer_token) { AccountManagerApplication.user_token(user.id).token }

  let(:account_api_application) { FactoryBot.create(:oauth_application) }

  around do |example|
    ClimateControl.modify(ATTRIBUTE_SERVICE_URL: attribute_service_url, ACCOUNT_API_DOORKEEPER_UID: account_api_application.uid) do
      example.run
    end
  end

  context "#destroy!" do
    it "calls the attribute service to delete the attributes" do
      stub_account_api_delete_user_by_subject_identifier(subject_identifier: user.generate_subject_identifier)
      attribute_service_stub = stub_attribute_service_delete_all
      user.destroy!
      expect(attribute_service_stub).to have_been_made
    end

    it "calls the account-api to delete remote data held there" do
      stub_attribute_service_delete_all
      account_api_delete_user_stub = stub_account_api_delete_user_by_subject_identifier(subject_identifier: user.generate_subject_identifier)
      user.destroy!
      expect(account_api_delete_user_stub).to have_been_made
    end

    def stub_attribute_service_delete_all
      stub_request(:delete, "#{attribute_service_url}/v1/attributes/all")
        .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
        .to_return(status: 200)
    end
  end

  context "#phone" do
    it "is formatted in E.164 format on save" do
      user.update!(phone: "07958 123 456")

      expect(user.phone).to eq("+447958123456")
    end
  end
end
