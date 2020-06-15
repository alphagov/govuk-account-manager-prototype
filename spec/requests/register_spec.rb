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
      KeycloakAdmin::UserRepresentation.from_hash(
        "id" => SecureRandom.uuid,
        "email" => email,
      )
    end

    before do
      users = double("users")
      allow(users).to receive(:get)
      allow(users).to receive(:update)
      allow(Services.keycloak).to receive(:users).and_return(users)
      allow(Services.keycloak.users).to receive(:create!).and_return(user)
      allow(EmailConfirmation).to receive(:send)
    end

    it "requests Keycloak creates a user" do
      expect(Services.keycloak.users).to receive(:create!).with(
        email,
        email,
        password,
        false,
        "en",
      )

      post register_path, params: params
    end

    it "sends an email" do
      expect(EmailConfirmation).to receive(:send).with(instance_of(KeycloakAdmin::UserRepresentation))

      post register_path, params: params
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
