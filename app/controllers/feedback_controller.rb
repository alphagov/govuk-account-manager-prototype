class FeedbackController < ApplicationController
  REQUIRED_FIELDS = %w[comments email response_required].freeze

  def show
    @form_responses = {}
  end

  def submit
    @form_responses = {
      email: strip_tags(params[:email]).presence,
      comments: strip_tags(params[:comments]).presence,
      response_required: strip_tags(params[:response_required]).presence,
    }

    errors = []
    REQUIRED_FIELDS.each do |field|
      errors << { field: field, text: I18n.t("feedback.fields.#{field}.not_present_error") } if @form_responses[field.to_sym].blank?
    end

    unless errors.empty?
      flash.now[:validation] = errors
      return render "show"
    end

    ticket_attributes = {
      subject: I18n.t("feedback.email_subject"),
      email: @form_responses[:email],
      comments: @form_responses[:comments],
      response_required: @form_responses[:response_required].humanize,
    }

    ZendeskTicketWorker.perform_async(ticket_attributes)
  end
end
