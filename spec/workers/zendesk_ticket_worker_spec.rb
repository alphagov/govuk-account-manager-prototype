RSpec.describe ZendeskTicketWorker, type: :worker do
  subject(:worker) { described_class.new }

  let(:ticket_attributes) do
    {
      subject: I18n.t("feedback.email_subject"),
      email: "someone@digital.cabinet-office.gov.uk",
      comments: "This website is awesome",
      response_required: "Yes",
    }
  end

  before do
    stub_request(:post, "https://govuk.zendesk.com/api/v2/tickets")
  end

  it "creates a Zendesk ticket with given parameters" do
    expect(Zendesk::Ticket).to receive(:new).once.with(ticket_attributes).and_call_original

    described_class.new.perform(ticket_attributes)
  end
end
