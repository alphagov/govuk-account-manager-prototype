RSpec.describe RemoteUserInfo, type: :unit do
  let(:attribute_service_url) { "https://attribute-service" }

  let(:user) do
    FactoryBot.create(
      :user,
      email: "user@domain.tld",
      password: "breadbread1",
      password_confirmation: "breadbread1",
    )
  end

  before do
    ENV["ATTRIBUTE_SERVICE_URL"] = attribute_service_url
  end

  context "the attribute service is down" do
    let(:token) do
      FactoryBot.create(
        :oauth_access_token,
        resource_owner_id: user.id,
        application_id: AccountManagerApplication.fetch.id,
        scopes: RemoteUserInfo::TOKEN_SCOPES,
      )
    end

    before do
      stub_request(:get, "#{attribute_service_url}/oidc/user_info")
        .with(headers: { accept: "application/json", authorization: "Bearer #{token.token}" })
        .to_return(status: 500)
    end

    it "returns nil" do
      expect(described_class.call(user)).to be_nil
    end
  end

  context "the attribute service is up" do
    context "the access token does not exist" do
      it "creates a new token and calls the attribute service with it" do
        attributes = { attribute: "value" }

        token = described_class.new(user).token
        expect(token).to_not be_nil
        expect(token.application_id).to eq(AccountManagerApplication.fetch.id)
        expect(token.expires_in).to be_nil
        expect(token.resource_owner_id).to eq(user.id)
        expect(token.scopes).to eq(RemoteUserInfo::TOKEN_SCOPES)

        stub_request(:get, "#{attribute_service_url}/oidc/user_info")
          .with(headers: { accept: "application/json", authorization: "Bearer #{token.token}" })
          .to_return(body: attributes.to_json)

        expect(described_class.call(user)).to eq(attributes)
      end
    end

    context "the access token exists" do
      let(:token) do
        FactoryBot.create(
          :oauth_access_token,
          resource_owner_id: user.id,
          application_id: AccountManagerApplication.fetch.id,
          scopes: RemoteUserInfo::TOKEN_SCOPES,
        )
      end

      it "calls the attribute service with it" do
        attributes = { attribute: "value" }

        stub_request(:get, "#{attribute_service_url}/oidc/user_info")
          .with(headers: { accept: "application/json", authorization: "Bearer #{token.token}" })
          .to_return(body: attributes.to_json)

        expect(described_class.call(user)).to eq(attributes)
      end

      context "#update_profile!" do
        it "calls the attribute service to set the profile attributes" do
          email_stub = stub_request(:put, "#{attribute_service_url}/v1/attributes/email")
            .with(headers: { accept: "application/json", authorization: "Bearer #{token.token}" }, body: { value: user.email })
            .to_return(status: 200)
          email_verified_stub = stub_request(:put, "#{attribute_service_url}/v1/attributes/email_verified")
            .with(headers: { accept: "application/json", authorization: "Bearer #{token.token}" }, body: { value: user.confirmed? })
            .to_return(status: 200)

          described_class.new(user).update_profile!

          expect(email_stub).to have_been_made
          expect(email_verified_stub).to have_been_made
        end
      end
    end
  end
end
