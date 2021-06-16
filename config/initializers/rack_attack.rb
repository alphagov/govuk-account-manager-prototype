RATE_LIMIT_COUNT = 16
RATE_LIMIT_PERIOD = 1.minute

Rack::Attack.throttle("limit /sign-in* attempts per IP", limit: RATE_LIMIT_COUNT, period: RATE_LIMIT_PERIOD) do |request|
  if request.path.is_a?(String) && request.path.start_with?("/sign-in") && request.post?
    "#{request.path} #{request.env['action_dispatch.remote_ip']}"
  end
end

Rack::Attack.throttle("limit /new-account* attempts per IP", limit: RATE_LIMIT_COUNT, period: RATE_LIMIT_PERIOD) do |request|
  if request.path.is_a?(String) && request.path.start_with?("/new-account") && request.post?
    "#{request.path} #{request.env['action_dispatch.remote_ip']}"
  end
end

Rack::Attack.throttled_response = lambda do |_request|
  html = ApplicationController.render(
    template: "standard_errors/generic",
    assigns: { error: :too_many_requests },
  )

  [429, { "Content-Type" => "text/html" }, [html]]
end
