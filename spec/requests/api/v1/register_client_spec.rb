RSpec.describe "/api/v1/register-client" do
  around do |example|
    ClimateControl.modify(ENABLE_DYNAMIC_REGISTRATION: "1") do
      example.run
    end
  end

  let(:headers) do
    {
      "Accept": "application/json",
      "Content-Type": "application/json",
    }
  end

  let(:payload) do
    {
      client_name: "my client",
      redirect_uris: ["http://foo"],
      subject_type: "pairwise",
    }
  end

  context "with all required fields" do
    it "responds with the client id and secret" do
      post api_v1_register_client_path, params: payload.to_json, headers: headers

      expect(response).to be_successful
      expect(JSON.parse(response.body).deep_symbolize_keys).to include({
        client_id: Doorkeeper::Application.last.uid,
        client_secret: Doorkeeper::Application.last.secret,
        client_secret_expires_at: 0,
      })
    end
  end

  context "with an array of redirect_uris" do
    it "responds with the client id and secret" do
      redirect_uris = ["http://foo1", "http://foo2"]
      payload[:redirect_uris] = redirect_uris

      post api_v1_register_client_path, params: payload.to_json, headers: headers

      expect(response).to be_successful
      expect(JSON.parse(response.body).deep_symbolize_keys).to include({
        client_id: Doorkeeper::Application.last.uid,
        client_secret: Doorkeeper::Application.last.secret,
        client_secret_expires_at: 0,
      })
      expect(Doorkeeper::Application.last.redirect_uri).to eq(redirect_uris.join("\n"))
    end
  end

  context "with a non-pairwise subject_type" do
    it "responds with 400 response code when value present but not pairwise" do
      payload[:subject_type] = "not_pairwise"

      post api_v1_register_client_path, params: payload.to_json, headers: headers

      expect(response).to have_http_status(400)
      expect(JSON.parse(response.body).deep_symbolize_keys).to eq({
        error: "unacceptable_subject_type",
        error_description: "subject_type must be pairwise",
      })
    end

    it "responds with the client id and secret when value not present" do
      post api_v1_register_client_path, params: payload.except(:subject_type).to_json, headers: headers

      expect(response).to be_successful
      expect(JSON.parse(response.body).deep_symbolize_keys).to include({
        client_id: Doorkeeper::Application.last.uid,
        client_secret: Doorkeeper::Application.last.secret,
        client_secret_expires_at: 0,
      })
    end
  end

  context "with a non-array redirect_uris" do
    it "responds with the client id and secret" do
      payload[:redirect_uris] = "http://foo"

      post api_v1_register_client_path, params: payload.to_json, headers: headers

      expect(response).to be_successful
      expect(JSON.parse(response.body).deep_symbolize_keys).to include({
        client_id: Doorkeeper::Application.last.uid,
        client_secret: Doorkeeper::Application.last.secret,
        client_secret_expires_at: 0,
      })
    end
  end

  context "without redirect_uris value" do
    it "responds with 400 response code" do
      post api_v1_register_client_path, params: payload.except(:redirect_uris).to_json, headers: headers

      expect(response).to have_http_status(400)
      expect(JSON.parse(response.body).deep_symbolize_keys).to eq({
        error: "invalid_client_metadata",
        error_description: "Required parameter redirect_uris missing",
      })
    end
  end

  context "with optional fields" do
    OPTIONAL_STRING_FIELDS =
      %w[
        logo_uri
        client_uri
        policy_uri
      ].freeze

    OPTIONAL_STRING_FIELDS.each do |field|
      it "responds with the client id, secret and optional fields when #{field} present" do
        payload[field] = "some_string"

        post api_v1_register_client_path, params: payload.to_json, headers: headers

        expect(response).to be_successful

        parsed_response = JSON.parse(response.body).deep_symbolize_keys
        expect(parsed_response).to include({
          client_id: Doorkeeper::Application.last.uid,
          client_secret: Doorkeeper::Application.last.secret,
          client_secret_expires_at: 0,
        })
        expect(parsed_response[field.to_sym]).to eq("some_string")
      end
    end

    OPTIONAL_ARRAY_FIELDS =
      %w[
        contacts
      ].freeze

    OPTIONAL_ARRAY_FIELDS.each do |field|
      it "responds with the client id, secret and optional fields when #{field} present" do
        payload[field] = %w[some_string another_string]

        post api_v1_register_client_path, params: payload.to_json, headers: headers

        expect(response).to be_successful

        parsed_response = JSON.parse(response.body).deep_symbolize_keys
        expect(parsed_response).to include({
          client_id: Doorkeeper::Application.last.uid,
          client_secret: Doorkeeper::Application.last.secret,
          client_secret_expires_at: 0,
        })
        expect(parsed_response[field.to_sym]).to eq(%w[some_string another_string])
      end
    end

    context "when trying to register a duplicated client name" do
      it "responds with 400 response code for the second request" do
        post api_v1_register_client_path, params: payload.to_json, headers: headers
        expect(response).to be_successful

        post api_v1_register_client_path, params: payload.to_json, headers: headers
        expect(response).to have_http_status(400)
        expect(JSON.parse(response.body).deep_symbolize_keys).to eq({
          error: "invalid_client_name",
          error_description: "Client ID already exists",
        })
      end
    end
  end
end
