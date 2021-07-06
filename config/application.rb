# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module GovukAccountManagerPrototype
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.active_job.queue_adapter = :sidekiq

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Match the content security policy by disabling framing
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options
    config.action_dispatch.default_headers["X-Frame-Options"] = "DENY"

    # Add permissions policy to opt out of FLoC
    config.action_dispatch.default_headers["Permissions-Policy"] = "interest-cohort=()"

    # GOV.UK convention is to use lib over app/lib
    config.autoload_paths << "lib"

    # GOV.UK convention is to use London time (but not for ActiveRecord)
    config.time_zone = "London"

    config.exceptions_app = routes

    config.warn_about_transition_checker_when_logging_in_to_a_missing_account = true

    config.allow_insecure_change_credential = false

    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml").to_s]

    config.i18n.default_locale = :en

    config.feature_flag_enforce_levels_of_authentication = ENV["FEATURE_FLAG_ENFORCE_LEVELS_OF_AUTHENTICATION"] == "enabled"
  end
end
