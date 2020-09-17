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
      render "show"
    end
  end
end
