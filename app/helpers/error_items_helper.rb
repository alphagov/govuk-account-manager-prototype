module ErrorItemsHelper
  def error_items(field, error_items)
    errors_for_field = (error_items || []).filter_map { |item| item[:text] if item[:field] == field }.uniq
    return unless errors_for_field.any?

    sanitize(errors_for_field.join("<br>"))
  end

  def devise_error_items(field, resource_error_messages = nil)
    raw_errors = resource ? resource.errors.messages : resource_error_messages
    return nil unless raw_errors

    content_for :title_prefix, t("errors.error") unless content_for?(:title_prefix)
    all_errors = raw_errors.compact.map do |id, errors|
      errors.map do |error|
        { field: id, error: error }
      end
    end

    resource_errors = all_errors.flatten.select { |item| item[:field] == field && item[:error].present? }

    if resource_errors.any?
      sanitize(resource_errors
        .pluck(:error)
        .join("<br>"))
    end
  end

  PREVIOUS_URL_IGNORE_LIST = %w[
    /
    /account
  ].freeze

  PREVIOUS_URL_IGNORE_PATH_STARTS_WITH = %w[
    /oauth/
  ].freeze

  def previous_url_is_on_ignore_list(previous_url)
    PREVIOUS_URL_IGNORE_LIST.include?(previous_url) || include_starts_with?(previous_url)
  end

  def include_starts_with?(previous_url)
    PREVIOUS_URL_IGNORE_PATH_STARTS_WITH.any? { |path| previous_url.start_with?(path) }
  end

  def remove_flash_alert
    flash[:alert] = nil
  end
end
