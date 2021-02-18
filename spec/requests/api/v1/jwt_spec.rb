RSpec.describe "/api/v1/jwt" do
  let(:application) { FactoryBot.create(:oauth_application) }

  let(:user) { nil }

  let(:token) do
    FactoryBot.create(
      :oauth_access_token,
      application_id: application.id,
      resource_owner_id: user&.id,
    )
  end

  let(:headers) do
    {
      Accept: "application/json",
      Authorization: "Bearer #{token.token}",
    }
  end

  let(:jwt_payload) do
    {
      scopes: [],
      attributes: {},
      post_register_oauth: "/oauth/authorize/foo",
    }
  end

  let(:params) do
    {
      jwt: JWT.encode(jwt_payload, nil, "none"),
    }
  end

  it "accepts a JWT" do
    post api_v1_jwt_path, params: params, headers: headers
    expect(response).to be_successful

    body = JSON.parse(response.body)
    expect(body).to eq({ "id" => Jwt.last.id })
    expect(Jwt.find(body["id"]).jwt_payload.deep_symbolize_keys).to match(
      jwt_payload.merge(application: hash_including(id: application.id)),
    )
  end

  context "a user access token is used" do
    let(:user) { FactoryBot.create(:user) }

    it "rejects" do
      post api_v1_jwt_path, params: params, headers: headers
      expect(response).to have_http_status(:bad_request)
    end
  end
end
