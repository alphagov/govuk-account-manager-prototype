RSpec.describe Jwt do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { FactoryBot.create(:user) }

  let!(:application) do
    FactoryBot.create(
      :oauth_application,
      name: "name",
      redirect_uri: "http://localhost",
      scopes: application_scopes,
    )
  end

  let(:application_scopes) { %i[test_scope_write] }

  let(:access_token) { FactoryBot.create(:oauth_access_token, application_id: application.id) }

  let(:jwt_payload) do
    {
      attributes: jwt_attributes,
      post_register_oauth: jwt_post_register_oauth,
    }.compact
  end

  let(:jwt_attributes) { { test: "value" } }
  let(:jwt_post_register_oauth) { "#{Rails.application.config.redirect_base_url}/oauth/authorize?some-other-query-string" }
  let(:jwt_application_id) { application.id }

  let(:jwt) { Jwt.create!(jwt_payload: JWT.encode(jwt_payload, nil, "none"), application_id_from_token: jwt_application_id) }

  context "#jwt_payload" do
    it "accepts" do
      payload = jwt.jwt_payload.deep_symbolize_keys
      expect(payload).to match({
        application: hash_including(id: application.id),
        scopes: application.scopes.to_a,
        attributes: jwt_attributes,
        post_register_oauth: jwt_post_register_oauth.delete_prefix(Rails.application.config.redirect_base_url),
      })
    end

    context "the JWT references a missing application" do
      let(:jwt_application_id) { "breadbread" }

      it "rejects" do
        expect { jwt }.to raise_error(Jwt::ApplicationNotFound)
      end
    end

    context "the JWT tries to write to an attribute not covered by the application scopes" do
      let(:application_scopes) { [] }

      it "rejects" do
        expect { jwt }.to raise_error(Jwt::InsufficientScopes)
      end
    end

    context "the JWT tries to write to an unknown attribute" do
      let(:jwt_attributes) { { foo: "bar" } }

      it "rejects" do
        expect { jwt }.to raise_error(Jwt::InsufficientScopes)
      end
    end

    context "the JWT is missing the optional post-register redirect" do
      let(:jwt_post_register_oauth) { nil }

      it "accepts" do
        expect { jwt }.to_not raise_error
      end
    end

    context "the JWT has a bad redirect" do
      let(:jwt_post_register_oauth) { "https://www.example.com" }

      it "rejects" do
        expect { jwt }.to raise_error(Jwt::InvalidOAuthRedirect)
      end
    end
  end

  context "#expired" do
    it "doesn't include JWTs attached to a RegistrationState" do
      freeze_time do
        jwt = Jwt.create!(created_at: (Jwt::EXPIRATION_AGE + 1.minute).ago, jwt_payload: "old", skip_parse_jwt_token: true)
        RegistrationState.create!(
          state: :start,
          email: "email@example.com",
          jwt_id: jwt.id,
        )

        expect(Jwt.expired.count).to eq(0)
      end
    end

    it "doesn't include JWTs attached to a LoginState" do
      freeze_time do
        jwt = Jwt.create!(created_at: (Jwt::EXPIRATION_AGE + 1.minute).ago, jwt_payload: "old", skip_parse_jwt_token: true)
        LoginState.create!(
          created_at: Time.zone.now,
          user: user,
          redirect_path: "/",
          jwt_id: jwt.id,
        )

        expect(Jwt.expired.count).to eq(0)
      end
    end
  end
end
