class FeedbackController < ApplicationController
  REQUIRED_FIELDS = %w[comments name email user_requires_response].freeze

  def show
    @form_responses = {}
  end

  def submit
    @form_responses = {
      name: strip_tags(params[:name]).presence,
      email: strip_tags(params[:email]).presence,
      comments: strip_tags(params[:comments]).presence,
      user_requires_response: strip_tags(params[:user_requires_response]).presence,
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
      name: @form_responses[:name],
      email: @form_responses[:email],
      comments: @form_responses[:comments],
      user_requires_response: @form_responses[:user_requires_response].humanize,
    }

    ZendeskTicketWorker.perform_async(ticket_attributes)
  end
end
