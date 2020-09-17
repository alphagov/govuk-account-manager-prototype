RSpec.describe Zendesk::Ticket, type: :unit do
  context "with a valid request" do
    let(:ticket_attributes) do
      {
        subject: "Support Request",
        email: "someone@digital.cabinet-office.gov.uk",
        comments: "This site is awesome",
        response_required: "No",
      }
    end

    let(:logger) { double("logger") }
    let(:client) { GDSZendesk::DummyClient.new(logger: logger) }

    it "creates a Zendesk ticket" do
      expected_attributes = {
        "subject" => "Support Request",
        "requester" => {
          "locale_id" => 1,
          "email" => "someone@digital.cabinet-office.gov.uk",
        },
        "comment" => {
          "body" => "[Details]\nThis site is awesome\n\n[Response Required]\nNo\n",
        },
      }
      expect(logger).to receive(:info).with("Zendesk ticket created: #{expected_attributes.inspect}")

      ticket = described_class.new(ticket_attributes).attributes
      client.ticket.create!(ticket)
    end
  end
end
