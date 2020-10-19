# frozen_string_literal: true

source "https://rubygems.org"

ruby File.read(".ruby-version").strip

gem "bootsnap", ">= 1.4.2"
gem "composite_primary_keys", "~> 12.0.0"
gem "devise"
gem "doorkeeper"
gem "doorkeeper-openid_connect"
gem "gds-api-adapters", "~> 67.0.1"
gem "gds_zendesk", "~> 3.2"
gem "geocoder"
gem "govuk_publishing_components", "21.69.0"
gem "jwt"
gem "notifications-ruby-client", "~> 5.3"
gem "pg"
gem "puma", "~> 5.0"
gem "rails", "~> 6.0.3"
gem "railties"
gem "rest-client", "~> 2.1.0"
gem "sass-rails", "~> 5.0.8"
gem "sentry-raven", "~> 3.0"
gem "sidekiq", "~> 6.1"
gem "sidekiq-scheduler", "~> 3.0.0"
gem "sprockets-rails"

group :development, :test do
  gem "byebug"
  gem "capybara"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "rspec-rails"
end

group :test do
  gem "climate_control"
  gem "govuk_test", "~> 2.0"
  gem "oauth2"
  gem "simplecov"
  gem "webmock"
end

group :development do
  gem "awesome_print"
  gem "listen", "~> 3.2"
  gem "pry-rails"
  gem "rubocop-govuk"
end
