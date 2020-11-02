module CookiesHelper
  def cookies_policy_header(user)
    "cookies_policy={\"essential\": true, \"settings\": false, \"usage\": #{user.cookie_consent}, \"campaigns\": false}; path=/"
  end
end
