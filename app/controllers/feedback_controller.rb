require "zendesk/ticket"

class FeedbackController < ApplicationController
  REQUIRED_FIELDS = %w[comments email response_required].freeze

  def show; end

  def submit
    errors = []
    REQUIRED_FIELDS.each do |field|
      errors << { field: field, text: I18n.t("feedback.fields.#{field}.not_present_error") } if params[field.to_sym].blank?
    end

    unless errors.empty?
      flash.now[:validation] = errors
      return render "show"
    end

    ticket_attributes = {
      subject: I18n.t("feedback.email_subject"),
      email: params[:email],
      comments: params[:comments],
      response_required: params[:response_required].humanize,
    }

    ticket = Zendesk::Ticket.new(ticket_attributes).attributes
    GDS_ZENDESK_CLIENT.ticket.create!(ticket)
  end
end
