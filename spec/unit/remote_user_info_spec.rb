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

  let(:basic_attributes) { described_class.new(user).basic_user_info }

  before do
    ENV["ATTRIBUTE_SERVICE_URL"] = attribute_service_url
  end

  context "the application does not exist" do
    it "returns the basic user info" do
      expect(described_class.call(user)).to eq(basic_attributes)
    end
  end

  context "the application exists" do
    let!(:application) do
      FactoryBot.create(
        :oauth_application,
        name: "GOV.UK Account Manager",
        redirect_uri: "https://www.gov.uk",
        scopes: RemoteUserInfo::TOKEN_SCOPES,
      )
    end

    context "the attribute service is down" do
      let(:token) do
        FactoryBot.create(
          :oauth_access_token,
          resource_owner_id: user.id,
          application_id: application.id,
          scopes: RemoteUserInfo::TOKEN_SCOPES,
        )
      end

      before do
        stub_request(:get, "#{attribute_service_url}/oidc/user_info")
          .with(headers: { accept: "application/json", authorization: "Bearer #{token.token}" })
          .to_return(status: 500)
      end

      it "returns the basic user info" do
        expect(described_class.call(user)).to eq(basic_attributes)
      end
    end

    context "the attribute service is up" do
      context "the access token does not exist" do
        it "creates a new token and calls the attribute service with it" do
          attributes = { attribute: "value" }

          token = described_class.new(user).token
          expect(token).to_not be_nil
          expect(token.application_id).to eq(application.id)
          expect(token.expires_in).to be_nil
          expect(token.resource_owner_id).to eq(user.id)
          expect(token.scopes).to eq(RemoteUserInfo::TOKEN_SCOPES)

          stub_request(:get, "#{attribute_service_url}/oidc/user_info")
            .with(headers: { accept: "application/json", authorization: "Bearer #{token.token}" })
            .to_return(body: attributes.to_json)

          expect(described_class.call(user)).to eq(attributes.merge(basic_attributes))
        end
      end

      context "the access token exists" do
        let(:token) do
          FactoryBot.create(
            :oauth_access_token,
            resource_owner_id: user.id,
            application_id: application.id,
            scopes: RemoteUserInfo::TOKEN_SCOPES,
          )
        end

        it "calls the attribute service with it" do
          attributes = { attribute: "value" }

          stub_request(:get, "#{attribute_service_url}/oidc/user_info")
            .with(headers: { accept: "application/json", authorization: "Bearer #{token.token}" })
            .to_return(body: attributes.to_json)

          expect(described_class.call(user)).to eq(attributes.merge(basic_attributes))
        end
      end
    end
  end
end
