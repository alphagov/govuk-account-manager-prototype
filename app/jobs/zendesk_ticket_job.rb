require "zendesk/ticket"

class ZendeskTicketJob < ApplicationJob
  queue_as :default

  def perform(ticket_attributes)
    ticket = Zendesk::Ticket.new(ticket_attributes).attributes
    GDS_ZENDESK_CLIENT.ticket.create!(ticket)
  rescue ZendeskAPI::Error::RecordInvalid => e
    raise e unless e.to_s.include? "is suspended."
  end
end
