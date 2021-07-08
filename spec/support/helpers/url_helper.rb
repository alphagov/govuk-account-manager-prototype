module UrlHelper
  def authorization_endpoint_url(options = {})
    parameters = {
      client_id: options[:client_id] || options[:client].try(:uid),
      redirect_uri: options[:redirect_uri] || options[:client].try(:redirect_uri),
      response_type: options[:response_type] || "code",
      scope: options[:scope],
      state: options[:state],
      code_challenge: options[:code_challenge],
      code_challenge_method: options[:code_challenge_method],
      _ga: options[:_ga],
    }.reject { |_, v| v.blank? }
    "/oauth/authorize?#{parameters.to_query}"
  end

  def user_root_path_on_govuk
    "#{Plek.new.website_root}/account/home"
  end
end

RSpec.configuration.send :include, UrlHelper
