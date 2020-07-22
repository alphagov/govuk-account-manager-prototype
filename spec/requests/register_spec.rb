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
      post new_user_registration_path, params: params

      follow_redirect!

      expect(response).to be_successful
      expect(response.body).to have_content(I18n.t("post_registration.title"))

      expect(User.last).to_not be_nil
      expect(User.last.email).to eq(email)
    end

    it "sends an email" do
      post new_user_registration_path, params: params

      follow_redirect!

      expect(response).to be_successful
      expect(response.body).to have_content(I18n.t("post_registration.title"))

      assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob
    end

    context "when the email is missing" do
      let(:email) { "" }

      it "shows an error" do
        post new_user_registration_path, params: params

        expect(response.body).to have_content("Email can't be blank")
      end
    end

    context "when the password is missing" do
      let(:password) { "" }

      it "returns an error" do
        post new_user_registration_path, params: params

        expect(response.body).to have_content("Password can't be blank")
      end
    end

    context "when the password confirmation is missing" do
      let(:password_confirmation) { "" }

      it "returns an error" do
        post new_user_registration_path, params: params

        expect(response.body).to have_content("Password confirmation doesn't match Password")
      end
    end

    context "when the password confirmation does not match" do
      let(:password_confirmation) { password + "-123" }

      it "returns an error" do
        post new_user_registration_path, params: params

        expect(response.body).to have_content("Password confirmation doesn't match Password")
      end
    end

    context "when the password is less than 8 characters" do
      let(:password) { "qwerty1" }

      it "returns an error" do
        post new_user_registration_path, params: params

        expect(response.body).to have_content("Password is too short (minimum is 8 characters)")
      end
    end

    context "when the password does not contain a number" do
      let(:password) { "qwertyui" }

      it "returns an error" do
        post new_user_registration_path, params: params

        expect(response.body).to have_content("Password is invalid")
      end
    end
  end
end
