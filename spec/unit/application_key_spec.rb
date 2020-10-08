RSpec.describe ApplicationKey, type: :unit do
  let!(:application) do
    FactoryBot.create(
      :oauth_application,
      name: "name",
      redirect_uri: "http://localhost",
      scopes: %i[test_scope_write],
    )
  end

  it "round-trips the PEM" do
    private_key = OpenSSL::PKey::EC.new "prime256v1"
    private_key.generate_key
    public_key = OpenSSL::PKey::EC.new private_key

    key = ApplicationKey.create!(
      application_uid: application.uid,
      key_id: SecureRandom.uuid,
      pem: public_key.to_pem,
    )

    expect(key.to_key.to_pem).to eq(public_key.to_pem)
  end

  context "validate_jwt!" do
    let(:private_key) do
      private_key = OpenSSL::PKey::EC.new "prime256v1"
      private_key.generate_key
    end

    let(:public_key) { OpenSSL::PKey::EC.new private_key }

    let(:application_key) do
      ApplicationKey.create!(
        application_uid: application.uid,
        key_id: SecureRandom.uuid,
        pem: public_key.to_pem,
      )
    end

    let(:jwt_uid) { application.uid }
    let(:jwt_key) { application_key.key_id }
    let(:jwt_scopes) { %i[test_scope_write] }
    let(:jwt_attributes) { { test: "value" } }
    let(:jwt_post_login_oauth) { "#{Rails.application.config.redirect_base_url}/oauth/authorize?some-query-string" }
    let(:jwt_signing_key) { private_key }

    let(:jwt) do
      payload = { uid: jwt_uid, key: jwt_key, scopes: jwt_scopes, attributes: jwt_attributes, post_login_oauth: jwt_post_login_oauth }.compact
      JWT.encode payload.compact, jwt_signing_key, "ES256"
    end

    it "accepts" do
      expect(ApplicationKey.validate_jwt!(jwt)).to include(:application, :signing_key, scopes: jwt_scopes, attributes: jwt_attributes, post_login_oauth: jwt_post_login_oauth)
      expect(ApplicationKey.validate_jwt!(jwt)[:application].uid).to eq(jwt_uid)
      expect(ApplicationKey.validate_jwt!(jwt)[:signing_key].to_key.to_pem).to eq(public_key.to_pem)
    end

    context "the JWT is missing a UID" do
      let(:jwt_uid) { nil }

      it "rejects" do
        expect { ApplicationKey.validate_jwt! jwt }.to raise_error(ApplicationKey::MissingFieldUid)
      end
    end

    context "the JWT is missing a key ID" do
      let(:jwt_key) { nil }

      it "rejects" do
        expect { ApplicationKey.validate_jwt! jwt }.to raise_error(ApplicationKey::MissingFieldKey)
      end
    end

    context "the JWT references a missing application" do
      let(:jwt_uid) { "breadbread" }

      it "rejects" do
        expect { ApplicationKey.validate_jwt! jwt }.to raise_error(ApplicationKey::UidNotFound)
      end
    end

    context "the JWT references a missing key" do
      let(:jwt_key) { "breadbread" }

      it "rejects" do
        expect { ApplicationKey.validate_jwt! jwt }.to raise_error(ApplicationKey::KeyNotFound)
      end
    end

    context "the JWT has been signed with the wrong key" do
      let(:jwt_signing_key) do
        private_key = OpenSSL::PKey::EC.new "prime256v1"
        private_key.generate_key
      end

      it "rejects" do
        expect { ApplicationKey.validate_jwt! jwt }.to raise_error(ApplicationKey::JWTDecodeError)
      end
    end

    context "the JWT asks for scopes the application doesn't have" do
      let(:jwt_scopes) { %i[account_manager_access] }

      it "rejects" do
        expect { ApplicationKey.validate_jwt! jwt }.to raise_error(ApplicationKey::InvalidScopes)
      end
    end

    context "the JWT tries to write to an attribute without requesting the scope" do
      let(:jwt_scopes) { [] }

      it "rejects" do
        expect { ApplicationKey.validate_jwt! jwt }.to raise_error(ApplicationKey::InsufficientScopes)
      end
    end

    context "the JWT tries to write to an unknown attribute" do
      let(:jwt_attributes) { { foo: "bar" } }

      it "rejects" do
        expect { ApplicationKey.validate_jwt! jwt }.to raise_error(ApplicationKey::InsufficientScopes)
      end
    end

    context "the JWT is missing the redirect" do
      let(:jwt_post_login_oauth) { nil }

      it "rejects" do
        expect { ApplicationKey.validate_jwt! jwt }.to raise_error(ApplicationKey::MissingFieldPostLoginOAuth)
      end
    end

    context "the JWT has a bad redirect" do
      let(:jwt_post_login_oauth) { "https://www.example.com" }

      it "rejects" do
        expect { ApplicationKey.validate_jwt! jwt }.to raise_error(ApplicationKey::InvalidOAuthRedirect)
      end
    end
  end
end
