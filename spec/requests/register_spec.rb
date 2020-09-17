RSpec.describe "register" do
  include ActiveJob::TestHelper

  describe "GET" do
    it "renders the form" do
      get new_user_registration_path

      expect(response.body).to have_content(I18n.t("devise.registrations.new.title"))
    end
  end

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
  end
end
