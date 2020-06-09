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
end
