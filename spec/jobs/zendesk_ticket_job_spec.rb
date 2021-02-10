RSpec.describe ZendeskTicketJob do
  let(:ticket_attributes) do
    {
      subject: I18n.t("feedback.email_subject"),
      email: "someone@digital.cabinet-office.gov.uk",
      comments: "This website is awesome",
      user_requires_response: "Yes",
    }
  end

  before do
    stub_request(:post, "https://govuk.zendesk.com/api/v2/tickets")
  end

  it "creates a Zendesk ticket with given parameters" do
    expect(Zendesk::Ticket).to receive(:new).once.with(ticket_attributes).and_call_original

    described_class.new.perform(ticket_attributes)
  end

  it "suppresses 'foo is suspended' errors" do
    error_hash = { details: [{ description: "Requester: #{ticket_attributes[:email]} is suspended." }] }.with_indifferent_access

    expect(Zendesk::Ticket).to receive(:new)
      .and_raise(ZendeskAPI::Error::RecordInvalid.new(nil, { body: error_hash }))

    described_class.new.perform(ticket_attributes)
  end
end
