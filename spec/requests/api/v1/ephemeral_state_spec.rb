RSpec.describe "/api/v1/ephemeral-state" do
  let(:user) { FactoryBot.create(:user) }

  let(:application) do
    FactoryBot.create(
      :oauth_application,
      name: "Some Other Government Service",
      redirect_uri: "https://www.gov.uk",
      scopes: %i[openid],
    )
  end

  let(:token) do
    FactoryBot.create(
      :oauth_access_token,
      resource_owner_id: user.id,
      application_id: application.id,
      scopes: %i[deanonymise_tokens],
    )
  end

  let(:headers) do
    {
      Accept: "application/json",
      Authorization: "Bearer #{token.token}",
    }
  end

  it "returns the ephemeral state" do
    EphemeralState.create!(user: user, token: token.token, ga_client_id: "hello world")
    get api_v1_ephemeral_state_path, headers: headers
    expect(JSON.parse(response.body).symbolize_keys).to eq({
      _ga: "hello world",
      cookie_consent: user.cookie_consent,
    })
  end

  it "deletes the state after returning it" do
    EphemeralState.create!(user: user, token: token.token, ga_client_id: "hello world")
    get api_v1_ephemeral_state_path, headers: headers
    expect(EphemeralState.count).to eq(0)
  end

  it "returns a 410 if the state is missing" do
    EphemeralState.create!(user: user, token: token.token, ga_client_id: "hello world")
    get api_v1_ephemeral_state_path, headers: headers
    get api_v1_ephemeral_state_path, headers: headers
    expect(response).to have_http_status(:gone)
  end
end
