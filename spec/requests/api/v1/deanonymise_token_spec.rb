RSpec.describe "/api/v1/deanonymise-token" do
  let(:user) { FactoryBot.create(:user) }

  let(:application) do
    FactoryBot.create(
      :oauth_application,
      name: "Some Other Government Service",
      redirect_uri: "https://www.gov.uk",
      scopes: %i[openid],
    )
  end

  let(:privileged_token) do
    FactoryBot.create(
      :oauth_access_token,
      resource_owner_id: user&.id,
      application_id: application.id,
      scopes: %i[deanonymise_tokens],
    )
  end

  let(:unprivileged_token) do
    FactoryBot.create(
      :oauth_access_token,
      resource_owner_id: user&.id,
      application_id: application.id,
      scopes: %i[openid],
    )
  end

  let(:bearer_token) { privileged_token }
  let(:check_token) { unprivileged_token }

  let(:headers) do
    {
      Accept: "application/json",
      Authorization: "Bearer #{bearer_token.token}",
    }
  end

  let(:params) do
    {
      token: check_token.token,
    }
  end

  context "with a privileged bearer token" do
    it "can deanonymise tokens" do
      get api_v1_deanonymise_token_path, params: params, headers: headers
      expect(response).to be_successful
      expect(JSON.parse(response.body).deep_symbolize_keys).to eq({
        pairwise_subject_identifier: Doorkeeper::OpenidConnect::UserInfo.new(check_token).claims[:sub],
        scopes: check_token.scopes.to_a,
        true_subject_identifier: user.id,
      })
    end

    context "with no associated user" do
      let(:user) { nil }

      it "returns just the scopes" do
        get api_v1_deanonymise_token_path, params: params, headers: headers
        expect(response).to be_successful
        expect(JSON.parse(response.body).deep_symbolize_keys).to eq({
          scopes: check_token.scopes.to_a,
        })
      end
    end

    context "with an expired check token" do
      let(:check_token) do
        FactoryBot.create(
          :oauth_access_token,
          resource_owner_id: user.id,
          application_id: application.id,
          scopes: %i[openid],
          expires_in: -1,
        )
      end

      it "throws a 410" do
        get api_v1_deanonymise_token_path, params: params, headers: headers
        expect(response).to have_http_status(410)
      end
    end

    context "with an unknown check token" do
      let(:params) do
        {
          token: ".",
        }
      end

      it "throws a 404" do
        get api_v1_deanonymise_token_path, params: params, headers: headers
        expect(response).to have_http_status(404)
      end
    end

    context "with no check token" do
      it "throws a 400" do
        get api_v1_deanonymise_token_path, headers: headers
        expect(response).to have_http_status(400)
      end
    end
  end

  context "with an unprivileged bearer token" do
    let(:bearer_token) { unprivileged_token }

    it "throws a 403" do
      get api_v1_deanonymise_token_path, params: params, headers: headers
      expect(response).to have_http_status(403)
    end
  end
end
