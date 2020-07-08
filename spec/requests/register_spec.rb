RSpec.describe "register" do
  describe "GET /register" do
    it "renders the form" do
      get register_path

      expect(response.body).to have_content(I18n.t("register.show.title"))
    end
  end

  describe "POST /register" do
    let(:params) do
      {
        email: email,
        password: password,
        password_confirm: password,
      }
    end

    let(:email) { "email@example.com" }
    let(:password) { "abcd1234" }

    let(:user) do
      # TODO: implement
    end

    before do
      # TODO: stub user retrieval
      allow(EmailConfirmation).to receive(:send)
    end

    it "creates a user" do
      # TODO: implement
    end

    it "sends an email" do
      # TODO: implement
    end

    it "shows an error when email is missing" do
      post register_path, params: params.merge(email: "")

      follow_redirect!
      expect(response.body).to have_content(I18n.t("register.create.error.email_missing"))
    end

    it "returns an error when new password is blank" do
      post register_path, params: params.merge(password: "")

      follow_redirect!
      expect(response.body).to have_content(I18n.t("register.create.error.password_missing"))
    end

    it "returns an error when password confirmation is blank" do
      post register_path, params: params.merge(password_confirm: "")

      follow_redirect!
      expect(response.body).to have_content(I18n.t("register.create.error.password_confirm_missing"))
    end

    it "returns an error when password confirmation does not match" do
      post register_path, params: params.merge(password_confirm: "foo")

      follow_redirect!
      expect(response.body).to have_content(I18n.t("register.create.error.password_mismatch"))
    end

    it "returns an error when password is less than 8 characters" do
      post register_path, params: params.merge(password: "qwerty1", password_confirm: "qwerty1")

      follow_redirect!
      expect(response.body).to have_content(I18n.t("register.create.error.password_invalid"))
    end

    it "returns an error when password does not contain a number" do
      post register_path, params: params.merge(password: "qwertyui", password_confirm: "qwertyui")

      follow_redirect!
      expect(response.body).to have_content(I18n.t("register.create.error.password_invalid"))
    end
  end
end
