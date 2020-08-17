require "cgi"

module PostRegistrationHelper
  def service_name_for(previous_url)
    return unless previous_url

    bits = previous_url.split("?")
    return unless bits.length > 1

    querystring = CGI.parse(bits[1])
    return unless querystring["client_id"]

    app = Doorkeeper::Application.by_uid(querystring["client_id"].first)
    return unless app

    app.name
  end
end
