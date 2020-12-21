RSpec.describe "JWT log in" do
  let(:application) do
    FactoryBot.create(
      :oauth_application,
      name: "name",
      redirect_uri: "http://localhost",
      scopes: application_scopes,
    )
  end

  let(:application_scopes) { %i[test_scope_read test_scope_write] }

  let(:private_key) do
    private_key = OpenSSL::PKey::EC.new "prime256v1" # pragma: allowlist secret
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

  let(:jwt_post_login_oauth) { "#{Rails.application.config.redirect_base_url}/oauth/authorize?some-query-string" }

  let(:jwt) do
    payload = {
      uid: application.uid,
      key: application_key.key_id,
      scopes: [],
      attributes: {},
      post_login_oauth: jwt_post_login_oauth,
    }.compact
    JWT.encode payload.compact, private_key, "ES256"
  end

  let!(:user) { FactoryBot.create(:user) }

  it "redirects the user to the OAuth consent flow" do
    post welcome_path, params: { "jwt" => jwt }
    post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password }
    expect(response).to redirect_to(jwt_post_login_oauth.delete_prefix(Rails.application.config.redirect_base_url))
  end

  it "preserves the JWT if the user comes from registration" do
    post welcome_path, params: { "jwt" => jwt }

    post new_user_registration_start_path, params: { "user[email]" => "email-for-this-test@example.com", "user[password]" => "password" }
    expect(RegistrationState.count).to be(1)

    post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password }
    expect(response).to redirect_to(jwt_post_login_oauth.delete_prefix(Rails.application.config.redirect_base_url))
  end

  context "the user is already logged in" do
    before do
      sign_in(user)
    end

    it "redirects the user to the OAuth consent flow" do
      post welcome_path, params: { "jwt" => jwt }
      expect(response).to redirect_to(jwt_post_login_oauth.delete_prefix(Rails.application.config.redirect_base_url))
    end
  end
end
