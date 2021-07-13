RSpec.describe "/api/v1/migrate-users-to-account-api" do
  let(:account_api_application) { FactoryBot.create(:oauth_application, name: "account-api") }
  let(:attribute_service_url) { "https://attribute-service" }

  around do |example|
    ClimateControl.modify(ATTRIBUTE_SERVICE_URL: attribute_service_url, ACCOUNT_API_DOORKEEPER_UID: account_api_application.uid) do
      example.run
    end
  end

  let(:token) do
    FactoryBot.create(
      :oauth_access_token,
      application_id: account_api_application.id,
      scopes: %i[migrate_users],
    )
  end

  let(:headers) do
    {
      Accept: "application/json",
      Authorization: "Bearer #{token.token}",
    }
  end

  let(:params) do
    {
      page: page,
    }.compact
  end

  let(:page) { 1 }

  before do
    stub_request(:get, "#{attribute_service_url}/oidc/user_info")
      .to_return(body: { transition_checker_state: { foo: "bar" } }.to_json)
  end

  it "returns a 200" do
    get api_v1_migrate_users_to_account_api_path, params: params, headers: headers
    expect(response).to be_successful
  end

  context "when there are more than PAGE_SIZE users" do
    let!(:users) { FactoryBot.create_list(:user, Api::V1::MigrateUsersToAccountApiController::PAGE_SIZE + 1) }

    it "returns users paginated by PAGE_SIZE" do
      get api_v1_migrate_users_to_account_api_path, params: params, headers: headers
      body = JSON.parse(response.body)
      expect(body["users"].count).to eq(Api::V1::MigrateUsersToAccountApiController::PAGE_SIZE)
      expect(body["is_last_page"]).to be(false)
    end
  end

  context "when a user is subscribed to Transition Checker emails" do
    let!(:user) { FactoryBot.create(:user) }
    let!(:subscription) { FactoryBot.create(:email_subscription, user_id: user.id) }

    it "marks the subscription as migrated" do
      get api_v1_migrate_users_to_account_api_path, params: params, headers: headers
      expect(subscription.reload.migrated_to_account_api).to be(true)
    end
  end

  context "with the page missing" do
    let(:page) { nil }

    it "returns a 400" do
      get api_v1_migrate_users_to_account_api_path, params: params, headers: headers
      expect(response).to have_http_status(:bad_request)
    end
  end
end
