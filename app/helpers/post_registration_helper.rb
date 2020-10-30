require "cgi"

module PostRegistrationHelper
  def service_for(previous_url, current_user)
    return unless previous_url&.start_with? oauth_authorization_path

    bits = previous_url.split("?")
    return unless bits.length > 1

    querystring = CGI.parse(bits[1])
    return unless querystring["client_id"]

    app = Doorkeeper::Application.by_uid(querystring["client_id"].first)
    return unless app

    url =
      if current_user&.cookie_consent && previous_url.end_with?("%3A%2Ftransition-check%2Fsaved-results")
        "#{previous_url}%3Acookies-yes"
      else
        previous_url
      end

    {
      name: app.name,
      url: url,
    }
  end
end
