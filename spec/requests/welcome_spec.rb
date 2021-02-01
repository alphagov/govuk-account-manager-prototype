RSpec.describe "welcome" do
  let(:application) do
    FactoryBot.create(
      :oauth_application,
      name: "name",
      redirect_uri: redirect_uri,
      scopes: application_scopes,
    )
  end

  let(:application_scopes) { %i[test_scope_read test_scope_write] }

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

  let(:redirect_uri) { Rails.application.config.redirect_base_url }

  let(:jwt_post_login_oauth_path) { "/oauth/authorize?some-query-string" }

  let(:jwt_post_login_oauth) { redirect_uri + jwt_post_login_oauth_path }

  let(:jwt) do
    payload = {
      uid: application.uid,
      key: application_key.key_id,
      scopes: [],
      attributes: {},
      post_login_oauth: jwt_post_login_oauth,
    }
    JWT.encode payload.compact, private_key, "ES256"
  end

  describe "GET" do
    context "when the user types the url directly or clicks the link in the banner" do
      before { get welcome_path }

      it "redirects the user to the account login page" do
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when the user arrives from the Brexit checker with a valid jwt" do
      before { post welcome_path, params: { "jwt" => jwt } }

      it "redirects the user to the account registration page" do
        expect(response).to redirect_to(new_user_registration_start_path)
      end
    end

    context "the user is logged in" do
      let(:user) { FactoryBot.create(:user) }

      before { sign_in(user) }

      context "when the user types the url directly or clicks the link in the banner" do
        before { get welcome_path }

        it "redirects the user to the account page" do
          expect(response).to redirect_to(user_root_path)
        end
      end

      context "when the user arrives from the Brexit checker with a valid jwt" do
        before { post welcome_path, params: { "jwt" => jwt } }

        it "redirects the user to the Jwt post login oauth route" do
          expect(response).to redirect_to(jwt_post_login_oauth_path)
        end
      end
    end
  end
end
