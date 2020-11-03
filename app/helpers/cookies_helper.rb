module CookiesHelper
  def cookies_policy_header(resource)
    "cookies_policy={\"essential\": true, \"settings\": false, \"usage\": #{resource.cookie_consent}, \"campaigns\": false}; path=/"
  end
end
