module ErrorItemsHelper
  def error_items(field)
    all_errors = resource.errors.messages.map do |id, errors|
      errors.map do |error|
        { field: id, error: error }
      end
    end

    resource_errors = all_errors.flatten.select { |item| item[:field] == field }

    if resource_errors.any?
      resource_errors
        .pluck(:error)
        .join("<br>")
    end
  end

  PREVIOUS_URL_IGNORE_LIST = %w[
    /
  ].freeze

  def previous_url_is_on_ignore_list(previous_url)
    PREVIOUS_URL_IGNORE_LIST.include?(previous_url)
  end

  def remove_flash_alert
    flash[:alert] = nil
  end
end
