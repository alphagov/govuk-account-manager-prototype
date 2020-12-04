module UrlHelper
  def add_param_to_url(url, name, value)
    return url if value.blank?

    if url.include? "?"
      "#{url}&#{name}=#{value}"
    else
      "#{url}?#{name}=#{value}"
    end
  end
end
