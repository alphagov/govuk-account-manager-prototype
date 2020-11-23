# frozen_string_literal: true

source "https://rubygems.org"

ruby File.read(".ruby-version").strip

gem "aws-ip"
gem "bootsnap"
gem "composite_primary_keys"
gem "devise"
gem "doorkeeper"
gem "doorkeeper-openid_connect"
gem "gds-api-adapters"
gem "gds_zendesk"
gem "geocoder"
gem "govuk_publishing_components"
gem "jwt"
gem "notifications-ruby-client"
gem "pg"
gem "puma"
gem "rack-attack"
gem "rails", "6.0.3.4"
gem "railties"
gem "rest-client"
gem "sass-rails"
gem "sentry-raven"
gem "sidekiq"
gem "sidekiq-scheduler"
gem "sprockets-rails"
gem "telephone_number"

group :development, :test do
  gem "byebug"
  gem "capybara"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "i18n-tasks", "~> 0.9.31"
  gem "rspec-rails"
end

group :test do
  gem "climate_control"
  gem "govuk_test"
  gem "oauth2"
  gem "simplecov"
  gem "webmock"
end

group :development do
  gem "awesome_print"
  gem "listen"
  gem "pry-rails"
  gem "rubocop-govuk"
end
