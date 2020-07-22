RSpec.describe "edit-password" do
  include ActiveJob::TestHelper

  let(:user) do
    FactoryBot.create(
      :user,
      email: "user@domain.tld",
      password: "breadbread1",
      password_confirmation: "breadbread1",
    )
  end

  let(:actual_reset_password_token) { user.send_reset_password_instructions }

  describe "GET" do
    it "renders the form" do
      get edit_user_password_url(user, reset_password_token: actual_reset_password_token)

      expect(response.body).to have_content(I18n.t("devise.passwords.edit.title"))
    end
  end

  describe "POST" do
    let(:params) do
      {
        "_method" => "put",
        "user[password]" => password,
        "user[password_confirmation]" => password_confirmation,
        "user[reset_password_token]" => reset_password_token,
      }
    end

    let(:password) { "abcd1234" }
    let(:password_confirmation) { password }
    let(:reset_password_token) { actual_reset_password_token }

    it "changes the user's password" do
      old_encrypted_password = user.encrypted_password

      post account_password_path, params: params

      follow_redirect!

      expect(response).to be_successful
      expect(old_encrypted_password).to_not eq(user.reload.encrypted_password)
    end

    context "when an incorrect token is provided" do
      let(:reset_password_token) { actual_reset_password_token + "-abc" }

      it "returns an error" do
        post account_password_path, params: params

        expect(response.body).to have_content("Reset password token is invalid")
      end
    end

    context "when the password is missing" do
      let(:password) { "" }

      it "returns an error" do
        post account_password_path, params: params

        expect(response.body).to have_content("Password can't be blank")
      end
    end

    context "when the password confirmation is missing" do
      let(:password_confirmation) { "" }

      it "returns an error" do
        post account_password_path, params: params

        expect(response.body).to have_content("Password confirmation doesn't match Password")
      end
    end

    context "when the password confirmation does not match" do
      let(:password_confirmation) { password + "-123" }

      it "returns an error" do
        post account_password_path, params: params

        expect(response.body).to have_content("Password confirmation doesn't match Password")
      end
    end

    context "when the password is less than 8 characters" do
      let(:password) { "qwerty1" }

      it "returns an error" do
        post account_password_path, params: params

        expect(response.body).to have_content("Password is too short (minimum is 8 characters)")
      end
    end

    context "when the password does not contain a number" do
      let(:password) { "qwertyui" }

      it "returns an error" do
        post account_password_path, params: params

        expect(response.body).to have_content("Password is invalid")
      end
    end
  end
end
