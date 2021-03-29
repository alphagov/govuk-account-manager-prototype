GovukError.configure do |config|
  config.before_send = lambda { |event, _hint|
    if event.extra.dig(:sidekiq, :job, :args, :arguments)
      event.extra[:sidekiq][:job][:args][:arguments] = []
    end
    if event.extra.dig(:sidekiq, :jobstr)
      event.extra[:sidekiq][:jobstr] = {}
    end
    event
  }
end
