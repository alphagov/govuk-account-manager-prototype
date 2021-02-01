RSpec.describe RemoteUserInfo do
  let(:attribute_service_url) { "https://attribute-service" }

  let(:user) { FactoryBot.create(:user) }

  let(:bearer_token) { AccountManagerApplication.user_token(user.id).token }

  around do |example|
    ClimateControl.modify(ATTRIBUTE_SERVICE_URL: attribute_service_url) do
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
    let(:body) { { attributes: { email: user.email.to_json, email_verified: user.confirmed?.to_json } } }

    it "calls the attribute service to set the profile attributes" do
      stub = stub_request(:post, "#{attribute_service_url}/v1/attributes")
        .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" }, body: body)
        .to_return(status: 200)

      described_class.new(user).update_profile!
      expect(stub).to have_been_made
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
end
