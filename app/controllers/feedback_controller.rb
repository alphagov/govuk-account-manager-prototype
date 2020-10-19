class FeedbackController < ApplicationController
  REQUIRED_FIELDS = %w[comments user_requires_response].freeze

  def show
    @form_responses = {}
    @form_responses[:email] = current_user[:email] if current_user
  end

  def submit
    @form_responses = {
      comments: strip_tags(params[:comments]).presence,
      user_requires_response: strip_tags(params[:user_requires_response]).presence,
    }

    conditionally_required_fields = []
    if @form_responses[:user_requires_response] == "yes"
      conditionally_required_fields = %w[name email]
      @form_responses[:name] = strip_tags(params[:name]).presence
      @form_responses[:email] = strip_tags(params[:email]).presence
    end

    errors = []
    (REQUIRED_FIELDS + conditionally_required_fields).each do |field|
      next if @form_responses[field.to_sym].present?

      errors << {
        field: field,
        href: "##{field}",
        text: I18n.t("feedback.show.fields.#{field}.not_present_error"),
      }
    end

    unless errors.empty?
      @error_items = errors
      return render "show"
    end

    ticket_attributes = {
      subject: I18n.t("feedback.show.email_subject"),
      name: @form_responses.fetch(:name, I18n.t("feedback.show.anonymous_name")),
      email: @form_responses.fetch(:email, I18n.t("feedback.show.anonymous_email")),
      comments: @form_responses[:comments],
      user_requires_response: @form_responses[:user_requires_response].humanize,
    }

    ZendeskTicketJob.perform_later ticket_attributes
  end
end
