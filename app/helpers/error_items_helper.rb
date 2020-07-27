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
end
