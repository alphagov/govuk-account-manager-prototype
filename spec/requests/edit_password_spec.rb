RSpec.describe "edit-password" do
  include ActiveJob::TestHelper

  let!(:user) { FactoryBot.create(:user) }

  let(:actual_reset_password_token) { user.send_reset_password_instructions }

  describe "GET" do
    it "renders the form" do
      get edit_user_password_url(user, reset_password_token: actual_reset_password_token)

      expect(response.body).to have_content(I18n.t("devise.passwords.edit.heading"))
    end
  end

  describe "POST" do
    let(:params) do
      {
        "_method" => "put",
        "user[password]" => password,
        "user[reset_password_token]" => reset_password_token,
      }
    end

    let(:password) { "abcd1234" }
    let(:reset_password_token) { actual_reset_password_token }

    it "changes the user's password" do
      old_encrypted_password = user.encrypted_password

      post user_password_path, params: params

      follow_redirect!

      expect(response).to be_successful
      expect(old_encrypted_password).to_not eq(user.reload.encrypted_password)
    end

    context "when an incorrect token is provided" do
      let(:reset_password_token) { actual_reset_password_token + "-abc" }

      it "returns an error" do
        post user_password_path, params: params

        expect(response.body).to have_content(I18n.t("activerecord.errors.models.user.attributes.reset_password_token.invalid"))
        expect(response.body).to_not have_selector("input[id='email']")
        expect(response.body).to have_selector("input[id='password'][autocomplete='off']")
      end
    end

    context "when the password is missing" do
      let(:password) { "" }

      it "returns an error" do
        post user_password_path, params: params

        expect(response.body).to have_content(I18n.t("activerecord.errors.models.user.attributes.password.blank"))
      end
    end

    context "when the password is less than 8 characters" do
      let(:password) { "qwerty1" }

      it "returns an error" do
        post user_password_path, params: params

        expect(response.body).to have_content(I18n.t("activerecord.errors.models.user.attributes.password.too_short"))
      end
    end

    context "when the password is on the denylist" do
      before do
        BannedPassword.import_list([password])
      end

      it "returns an error" do
        post user_password_path, params: params

        expect(response.body).to have_content(Rails::Html::FullSanitizer.new.sanitize(I18n.t("activerecord.errors.models.user.attributes.password.denylist")))
      end
    end
  end
end
