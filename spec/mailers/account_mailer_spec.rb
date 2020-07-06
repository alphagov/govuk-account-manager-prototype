RSpec.describe AccountMailer, type: :mailer do
  describe "#confirmation_email" do
    let(:mail) { AccountMailer.with(params).confirmation_email(to_address) }
    let(:to_address) { "user@example.org" }
    let(:params) { { link: "https://www.google.com" } }

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t("emails.confirmation.subject"))
      expect(mail.to).to eq([to_address])
      expect(mail.from).to eq(["test@example.org"])
    end

    it "includes the link in the body" do
      expect(mail.body.encoded).to include(params.dig(:link))
    end
  end

  describe "#reset_password_email" do
    let(:mail) { AccountMailer.with(params).reset_password_email(to_address) }
    let(:to_address) { "user@example.org" }
    let(:params) { { link: "https://www.google.com" } }

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t("emails.reset_password.subject"))
      expect(mail.to).to eq([to_address])
      expect(mail.from).to eq(["test@example.org"])
    end

    it "includes the link in the body" do
      expect(mail.body.encoded).to include(params.dig(:link))
    end
  end

  describe "#change_confirmation_email" do
    let(:mail) { AccountMailer.with(params).change_confirmation_email(to_address) }
    let(:to_address) { "user@example.org" }
    let(:params) { { link: "https://www.google.com" } }

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t("emails.change_confirmation.subject"))
      expect(mail.to).to eq([to_address])
      expect(mail.from).to eq(["test@example.org"])
    end

    it "includes the link in the body" do
      expect(mail.body.encoded).to include(params.dig(:link))
    end
  end

  describe "#change_cancel_email" do
    let(:mail) { AccountMailer.with(params).change_cancel_email(to_address) }
    let(:to_address) { "user@example.org" }
    let(:params) { { new_address: "user2@example.org", link: "https://www.google.com" } }

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t("emails.change_cancel.subject"))
      expect(mail.to).to eq([to_address])
      expect(mail.from).to eq(["test@example.org"])
    end

    it "includes the link in the body" do
      expect(mail.body.encoded).to include(params.dig(:link))
    end

    it "includes the new address in the body" do
      expect(mail.body.encoded).to include(params.dig(:new_address))
    end
  end
end
