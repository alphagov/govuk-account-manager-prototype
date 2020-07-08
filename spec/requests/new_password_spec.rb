RSpec.describe "new-password" do
  describe "GET /new-password" do
    it "renders the form" do
      get new_password_path

      expect(response.body).to have_content(I18n.t("new_password.title"))
    end
  end

  describe "POST /new-password" do
    let(:params) do
      {
        user_id: user.id,
        token: user.attributes["reset_password_verification_token"].first,
        password: "newpassword1",
        password_confirm: "newpassword1",
      }
    end

    let(:user) do
      # TODO: implement
    end

    let(:email) { "email@example.com" }
    let(:token) { "abc123" }
    let(:expires) { Time.zone.now + 24.hours }

    before do
      # TODO: stub user retrieval
    end

    it "returns an error when user_id not provided" do
      post new_password_path, params: params.except(:user_id)

      expect(response.body).to have_content(I18n.t("new_password.error.bad_parameters"))
    end

    it "returns an error when user_id is invalid" do
      post new_password_path, params: params.merge(user_id: "invalid_user")

      expect(response.body).to have_content(I18n.t("new_password.error.no_such_user"))
    end

    it "returns an error when token not provided" do
      post new_password_path, params: params.except(:token)

      expect(response.body).to have_content(I18n.t("new_password.error.bad_parameters"))
    end

    it "returns an error when token is invalid" do
      post new_password_path, params: params.merge(token: "invalid_token")

      expect(response.body).to have_content(I18n.t("new_password.error.token_mismatch"))
    end

    it "returns an error when new password is blank" do
      post new_password_path, params: params.merge(password: "")

      follow_redirect!
      expect(response.body).to have_content(I18n.t("new_password.error.password_missing"))
    end

    it "returns an error when password confirmation is blank" do
      post new_password_path, params: params.merge(password_confirm: "")

      follow_redirect!
      expect(response.body).to have_content(I18n.t("new_password.error.password_confirm_missing"))
    end

    it "returns an error when password confirmation does not match" do
      post new_password_path, params: params.merge(password_confirm: "foo")

      follow_redirect!
      expect(response.body).to have_content(I18n.t("new_password.error.password_mismatch"))
    end

    it "returns an error when password is less than 8 characters" do
      post new_password_path, params: params.merge(password: "qwerty1", password_confirm: "qwerty1")

      follow_redirect!
      expect(response.body).to have_content(I18n.t("new_password.error.password_invalid"))
    end

    it "returns an error when password does not contain a number" do
      post new_password_path, params: params.merge(password: "qwertyui", password_confirm: "qwertyui")

      follow_redirect!
      expect(response.body).to have_content(I18n.t("new_password.error.password_invalid"))
    end

    it "changes password with valid parameters" do
      # TODO: test update password call is made
    end
  end
end
