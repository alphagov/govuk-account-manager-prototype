RSpec.describe "register" do
  include ActiveJob::TestHelper
  describe "POST" do
    let(:params) do
      {
        "user[email]" => email,
        "user[password]" => password,
        "user[password_confirmation]" => password_confirmation,
      }
    end

    let(:email) { "email@example.com" }
    let(:password) { "abcd1234" }
    let(:password_confirmation) { password }

    it "creates a user" do
      post new_user_registration_post_path, params: params

      follow_redirect!

      expect(response).to be_successful
      expect(response.body).to have_content(I18n.t("post_registration.title"))

      expect(User.last).to_not be_nil
      expect(User.last.email).to eq(email)
    end

    it "sends an email" do
      post new_user_registration_post_path, params: params

      follow_redirect!

      expect(response).to be_successful
      expect(response.body).to have_content(I18n.t("post_registration.title"))

      assert_enqueued_jobs 1, only: NotifyDeliveryJob
    end

    context "when the email is missing" do
      let(:email) { "" }

      it "shows an error" do
        post new_user_registration_post_path, params: params

        expect(response.body).to have_content(I18n.t("activerecord.errors.models.user.attributes.email.blank"))
      end
    end

    context "when the email is invalid" do
      let(:email) { "foo" }

      it "shows an error" do
        post new_user_registration_post_path, params: params

        expect(response.body).to have_content(I18n.t("activerecord.errors.models.user.attributes.email.invalid"))
      end
    end

    context "when the password is missing" do
      let(:password) { "" }

      it "returns an error" do
        post new_user_registration_post_path, params: params

        expect(response.body).to have_content(I18n.t("activerecord.errors.models.user.attributes.password.blank"))
      end
    end

    context "when the password confirmation is missing" do
      let(:password_confirmation) { "" }

      it "returns an error" do
        post new_user_registration_post_path, params: params

        expect(response.body).to have_content(I18n.t("activerecord.errors.models.user.attributes.password_confirmation.confirmation"))
      end
    end

    context "when the password confirmation does not match" do
      let(:password_confirmation) { password + "-123" }

      it "returns an error" do
        post new_user_registration_post_path, params: params

        expect(response.body).to have_content(I18n.t("activerecord.errors.models.user.attributes.password_confirmation.confirmation"))
      end
    end

    context "when the password is less than 8 characters" do
      let(:password) { "qwerty1" }

      it "returns an error" do
        post new_user_registration_post_path, params: params

        expect(response.body).to have_content(I18n.t("activerecord.errors.models.user.attributes.password.too_short"))
      end
    end

    context "when the password does not contain a number" do
      let(:password) { "qwertyui" }

      it "returns an error" do
        post new_user_registration_post_path, params: params

        expect(response.body).to have_content(I18n.t("activerecord.errors.models.user.attributes.password.invalid"))
      end
    end

    context "when a valid JWT is given" do
      let(:application) do
        FactoryBot.create(
          :oauth_application,
          name: "name",
          redirect_uri: "http://localhost",
          scopes: %i[test_scope_write],
        )
      end

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
      let(:jwt_signing_key) { private_key }

      let(:jwt) do
        payload = { uid: jwt_uid, key: jwt_key, scopes: jwt_scopes, attributes: jwt_attributes }.compact
        JWT.encode payload.compact, jwt_signing_key, "ES256"
      end

      let(:params) do
        {
          "user[email]" => email,
          "user[password]" => password,
          "user[password_confirmation]" => password_confirmation,
          "jwt" => jwt,
        }
      end

      it "creates an access token" do
        post new_user_registration_post_path, params: params
        follow_redirect!
        expect(response).to be_successful

        token = Doorkeeper::AccessToken.last
        expect(token).to_not be_nil
        expect(token.resource_owner_id).to eq(User.last.id)
        expect(token.application.uid).to eq(jwt_uid)
        expect(token.expires_in).to eq(Doorkeeper.config.access_token_expires_in)
        expect(token.scopes).to eq(jwt_scopes)
      end

      it "updates the attributes" do
        post new_user_registration_post_path, params: params
        follow_redirect!
        expect(response).to be_successful

        assert_enqueued_jobs 1, only: SetAttributesJob
      end

      context "no scopes are requested" do
        let(:jwt_scopes) { [] }
        let(:jwt_attributes) { {} }

        it "does not create an access token" do
          expect {
            post new_user_registration_post_path, params: params
            follow_redirect!
            expect(response).to be_successful
          }.to_not(change { Doorkeeper::AccessToken.count })
        end
      end

      context "the user is not persisted" do
        let(:password) { "" }

        it "does not create an access token" do
          expect {
            post new_user_registration_post_path, params: params
            expect(response).to be_successful
          }.to_not(change { Doorkeeper::AccessToken.count })
        end
      end
    end
  end
end
