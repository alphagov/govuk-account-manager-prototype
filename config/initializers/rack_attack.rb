LIMIT_LOGIN_ATTEMPTS_PER_IP = 16

Rack::Attack.throttle("limit login attempts per IP", limit: LIMIT_LOGIN_ATTEMPTS_PER_IP, period: 1.hour) do |request|
  if request.path == "/sign-in" && request.post?
    request.env["action_dispatch.remote_ip"].to_s
  end
end

Rack::Attack.throttled_response = lambda do |_request|
  html = ApplicationController.render(
    template: "standard_errors/generic",
    assigns: { error: :too_many_requests },
  )

  [429, { "Content-Type" => "text/html" }, [html]]
end
