# frozen_string_literal: true

require "aws_ip"

Rails.application.configure do

  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.assets.compile = false
  config.log_level = :warn
  config.log_tags = [:request_id]
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  if ENV["VCAP_SERVICES"].present?
    redis = JSON.parse(ENV["VCAP_SERVICES"]).to_h.fetch("redis", [])
    instance = redis.first
    redis_url = instance.dig("credentials", "uri")

    Sidekiq.configure_server do |config|
      config.redis = { url: redis_url }
    end

    Sidekiq.configure_client do |config|
      config.redis = { url: redis_url }
    end
  elsif ENV["REDIS_URL"].present?
    Sidekiq.configure_server do |config|
      config.redis = { url: ENV["REDIS_URL"] }
    end

    Sidekiq.configure_client do |config|
      config.redis = { url: ENV["REDIS_URL"] }
    end
  end

  config.redirect_base_url = ENV["REDIRECT_BASE_URL"]

  config.action_mailer.delivery_method = :notify
  config.action_mailer.default_url_options = { host: ENV["REDIRECT_BASE_URL"] }

  config.action_dispatch.trusted_proxies = ActionDispatch::RemoteIp::TRUSTED_PROXIES + AwsIp.new
    .all_ranges
    .select { |range| range["service"] == "CLOUDFRONT" }
    .pluck("ip_prefix")
    .map { |proxy| IPAddr.new(proxy) }

  config.hosts = [
    ENV["REDIRECT_BASE_URL"].split("://")[1],
  ]
end
