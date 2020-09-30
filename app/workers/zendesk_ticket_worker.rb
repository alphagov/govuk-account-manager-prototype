require "zendesk/ticket"

class ZendeskTicketWorker
  include Sidekiq::Worker

  def perform(ticket_attributes)
    ticket = Zendesk::Ticket.new(ticket_attributes).attributes
    GDS_ZENDESK_CLIENT.ticket.create!(ticket)
  end
end
