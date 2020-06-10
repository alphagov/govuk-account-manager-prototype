require "email_confirmation"

RSpec.describe "lib/email_confirmation" do
  context "#send" do
    let(:user) { KeycloakAdmin::UserRepresentation.from_hash("email" => email) }
    let(:email) { "email@example.com" }

    before do
      users = double("users")
      allow(users).to receive(:update)
      allow(Services.keycloak).to receive(:users).and_return(users)
    end

    it "sends an email" do
      expect {
        EmailConfirmation.send(user)
      }.to have_enqueued_mail(AccountMailer, :confirmation_email)
        .on_queue("mailers")
    end
  end

  context "#check_and_verify" do
    context "when the user exists" do
      let(:user) { KeycloakAdmin::UserRepresentation.from_hash("attributes" => { "verification_token" => [token], "verification_token_expires" => [expires.to_s] }) }
      let(:token) { "hello world" }
      let(:expires) { Time.zone.now + 24.hours }

      before do
        users = double("users")
        allow(users).to receive(:update)
        allow(Services.keycloak).to receive(:users).and_return(users)
      end

      context "the token is valid" do
        it "returns :ok" do
          expect(EmailConfirmation.check_and_verify(user, token)).to be(:ok)
        end
      end

      context "the token is invalid" do
        it "returns :token_mismatch" do
          expect(EmailConfirmation.check_and_verify(user, "not the read #{token}")).to be(:token_mismatch)
        end
      end

      context "the token has expired" do
        let(:expires) { Time.zone.now - 24.hours }
        it "returns :token_expired" do
          expect(EmailConfirmation.check_and_verify(user, token)).to be(:token_expired)
        end
      end
    end

    context "when the user doesn't exist" do
      it "returns :no_such_user" do
        expect(EmailConfirmation.check_and_verify(nil, "doesn't matter")).to be(:no_such_user)
      end
    end
  end
end
