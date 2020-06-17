module ErrorItemsHelper
  def error_items(field)
    if flash[:validation] && flash[:validation].select { |error| error["field"].to_s == field }.any?
      sanitize(flash[:validation]
        .select { |error| error["field"].to_s == field }
        .map { |error| error["text"] }.uniq
        .join("<br>"))
    end
  end
end
