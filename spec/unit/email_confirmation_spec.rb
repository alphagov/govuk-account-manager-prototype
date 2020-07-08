require "email_confirmation"

RSpec.describe "lib/email_confirmation" do
  context "#send" do
    let(:user) {
      # TODO: implement
    }
    let(:email) { "email@example.com" }

    before do
      # TODO: stub user retrieval
    end

    it "sends an email" do
      expect {
        EmailConfirmation.send(user)
      }.to have_enqueued_mail(AccountMailer, :confirmation_email)
        .on_queue("mailers")
    end
  end

  context "#change_and_send" do
    let(:user) {
      # TODO: implement
    }
    let(:email) { "email@example.com" }
    let(:new_email) { "email2@example.com" }

    before do
      # TODO: stub user retrieval
    end

    it "sends an email to confirm the new address" do
      expect {
        EmailConfirmation.change_and_send(user, new_email)
      }.to have_enqueued_mail(AccountMailer, :change_confirmation_email)
        .on_queue("mailers")
    end

    it "sends an email to cancel the change" do
      expect {
        EmailConfirmation.change_and_send(user, new_email)
      }.to have_enqueued_mail(AccountMailer, :change_cancel_email)
        .on_queue("mailers")
    end
  end

  context "#check_and_verify" do
    context "when the user exists" do
      let(:user) {
        # TODO: implement
      }
      let(:token) { "hello world" }
      let(:expires) { Time.zone.now + 24.hours }

      before do
        # TODO: stub user retrieval
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

  context "#cancel_change" do
    context "when the user exists" do
      let(:user) {
        # TODO: implement
      }
      let(:new_address) { ["email@example.com"] }

      before do
        # TODO: stub user retrieval
      end

      context "the new address is present" do
        it "returns :ok" do
          expect(EmailConfirmation.cancel_change(user)).to be(:ok)
        end
      end

      context "the new address is missing" do
        let(:new_address) { nil }

        it "returns :too_late" do
          expect(EmailConfirmation.cancel_change(user)).to be(:too_late)
        end
      end
    end

    context "when the user doesn't exist" do
      it "returns :no_such_user" do
        expect(EmailConfirmation.cancel_change(nil)).to be(:no_such_user)
      end
    end
  end
end
