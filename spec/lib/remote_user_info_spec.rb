require "gds_api/test_helpers/account_api"

RSpec.describe RemoteUserInfo do
  include GdsApi::TestHelpers::AccountApi

  let(:attribute_service_url) { "https://attribute-service" }

  let(:user) { FactoryBot.create(:user) }

  let(:bearer_token) { AccountManagerApplication.user_token(user.id).token }

  let(:account_api_application) { FactoryBot.create(:oauth_application) }
  let(:account_api_subject_identifier) { Doorkeeper::OpenidConnect.configuration.subject.call(user, account_api_application).to_s }

  around do |example|
    ClimateControl.modify(ATTRIBUTE_SERVICE_URL: attribute_service_url, ACCOUNT_API_DOORKEEPER_UID: account_api_application.uid) do
      example.run
    end
  end

  context "#user_info" do
    let(:attributes) { { attribute: "value" } }

    it "calls the attribute service" do
      stub_request(:get, "#{attribute_service_url}/oidc/user_info")
        .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
        .to_return(body: attributes.to_json)

      expect(described_class.call(user)).to eq(attributes)
    end

    context "the attribute service is down" do
      before do
        stub_request(:get, "#{attribute_service_url}/oidc/user_info")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
          .to_return(status: 500)
      end

      it "returns nil" do
        expect(described_class.call(user)).to be_nil
      end
    end

    context "the attribute service sporadically times out" do
      let(:final_status) { 200 }

      before do
        stub_request(:get, "#{attribute_service_url}/oidc/user_info")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
          .to_return(status: 504)
        stub_request(:get, "#{attribute_service_url}/oidc/user_info")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
          .to_return(status: 504)
        stub_request(:get, "#{attribute_service_url}/oidc/user_info")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
          .to_return(status: final_status, body: attributes.to_json)
      end

      it "tries 3 times" do
        expect(described_class.call(user)).to eq(attributes)
      end

      context "the 3rd attempt fails" do
        let(:final_status) { 504 }

        it "returns nil" do
          expect(described_class.call(user)).to be_nil
        end
      end
    end
  end

  context "#update_profile!" do
    let(:attributes) { { email: user.email, email_verified: user.confirmed?, has_unconfirmed_email: !user.unconfirmed_email.nil? } }
    let(:body) { { attributes: attributes.transform_values(&:to_json) } }

    it "calls account-api and attribute-service to set the profile attributes" do
      stub_attribute_service = stub_request(:post, "#{attribute_service_url}/v1/attributes")
        .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" }, body: body)
        .to_return(status: 200)

      stub_account_api = stub_update_user_by_subject_identifier(subject_identifier: account_api_subject_identifier, **attributes)

      described_class.new(user).update_profile!
      expect(stub_attribute_service).to have_been_made
      expect(stub_account_api).to have_been_made
    end

    context "the attribute service sporadically times out" do
      let(:final_status) { 200 }

      before do
        stub_request(:post, "#{attribute_service_url}/v1/attributes")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" }, body: body)
          .to_return(status: 504)
        stub_request(:post, "#{attribute_service_url}/v1/attributes")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" }, body: body)
          .to_return(status: 504)
        @stub = stub_request(:post, "#{attribute_service_url}/v1/attributes")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" }, body: body)
          .to_return(status: final_status)
        stub_update_user_by_subject_identifier(subject_identifier: account_api_subject_identifier, **attributes)
      end

      it "tries 3 times" do
        described_class.new(user).update_profile!
        expect(@stub).to have_been_made
      end

      context "the 3rd attempt fails" do
        let(:final_status) { 504 }

        it "re-throws the exception" do
          expect { described_class.new(user).update_profile! }.to raise_error(RestClient::GatewayTimeout)
        end
      end
    end
  end

  context "#destroy!" do
    it "calls account-api and attribute-service to delete user data" do
      ClimateControl.modify ACCOUNT_API_DOORKEEPER_UID: account_api_application.uid do
        stub_attribute_service = stub_request(:delete, "#{attribute_service_url}/v1/attributes/all")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
          .to_return(status: 200)
        stub_account_api = stub_account_api_delete_user_by_subject_identifier(subject_identifier: account_api_subject_identifier)

        described_class.new(user).destroy!
        expect(stub_attribute_service).to have_been_made
        expect(stub_account_api).to have_been_made
      end
    end

    context "the attribute service sporadically times out" do
      let(:final_status) { 200 }

      before do
        stub_request(:delete, "#{attribute_service_url}/v1/attributes/all")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
          .to_return(status: 504)
        stub_request(:delete, "#{attribute_service_url}/v1/attributes/all")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
          .to_return(status: 504)
        @stub = stub_request(:delete, "#{attribute_service_url}/v1/attributes/all")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
          .to_return(status: final_status)
        stub_account_api_delete_user_by_subject_identifier(subject_identifier: account_api_subject_identifier)
      end

      it "tries to delete attributes 3 times" do
        described_class.new(user).destroy!
        expect(@stub).to have_been_made
      end

      context "the 3rd attribute service attempt fails" do
        let(:final_status) { 504 }

        it "re-throws the exception" do
          expect { described_class.new(user).destroy! }.to raise_error(RestClient::GatewayTimeout)
        end
      end
    end

    context "the account-api service sporadically times out" do
      let(:final_status) { 200 }

      before do
        stub_request(:delete, %r{/api/oidc-users/#{account_api_subject_identifier}})
          .with(headers: { accept: "application/json" })
          .to_return(status: 504)
        stub_request(:delete, %r{/api/oidc-users/#{account_api_subject_identifier}})
          .with(headers: { accept: "application/json" })
          .to_return(status: 504)
        @stub = stub_request(:delete, %r{/api/oidc-users/#{account_api_subject_identifier}})
          .with(headers: { accept: "application/json" })
          .to_return(status: final_status)

        stub_request(:delete, "#{attribute_service_url}/v1/attributes/all")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
          .to_return(status: 200)
      end

      it "tries to delete account-api data 3 times" do
        described_class.new(user).destroy!
        expect(@stub).to have_been_made
      end

      context "the 3rd account-api attempt fails" do
        let(:final_status) { 504 }

        it "re-throws the exception" do
          expect { described_class.new(user).destroy! }.to raise_error(GdsApi::HTTPGatewayTimeout)
        end
      end
    end
  end
end
