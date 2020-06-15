RSpec.describe "reset-password" do
  describe "GET /reset-password" do
    it "renders the form" do
      get reset_password_path

      expect(response.body).to have_content(I18n.t("reset_password.title"))
    end
  end

  describe "POST /reset-password" do
    let(:params) do
      {
        email: user.email,
      }
    end

    let(:user) do
      KeycloakAdmin::UserRepresentation.from_hash(
        "id" => SecureRandom.uuid,
        "email" => email,
      )
    end

    let(:email) { "email@example.com" }
    let(:token) { "abc123" }
    let(:expires) { Time.zone.now + 24.hours }

    before do
      users = double("users")
      allow(users).to receive(:get)
      allow(users).to receive(:update)
      allow(Services.keycloak).to receive(:users).and_return(users)
      allow(Services.keycloak.users).to receive(:search).with(user.email).and_return([user])
      allow(SecureRandom).to receive(:hex).and_return(token)
    end

    it "updates user attributes" do
      Timecop.freeze do
        expect(Services.keycloak.users).to receive(:update).with(user.id, instance_of(KeycloakAdmin::UserRepresentation))

        post reset_password_path, params: params
      end
    end

    it "sends an email" do
      expect {
        post reset_password_path, params: params
      }.to have_enqueued_mail(AccountMailer, :reset_password_email)
        .on_queue("mailers")
    end
  end
end
