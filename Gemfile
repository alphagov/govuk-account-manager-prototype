# frozen_string_literal: true

source "https://rubygems.org"

ruby File.read(".ruby-version").strip

gem "bootsnap", ">= 1.4.2"
gem "devise"
gem "doorkeeper"
gem "doorkeeper-openid_connect"
gem "geocoder"
gem "govuk_publishing_components", "21.59.0"
gem "notifications-ruby-client", "~> 5.1"
gem "pg"
gem "puma", "~> 4.1"
gem "rails", "~> 6.0.3"
gem "railties"
gem "sass-rails", "~> 6.0.0"
gem "sidekiq", "~> 6.1"
gem "sprockets-rails"

group :development, :test do
  gem "byebug"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "rspec-rails"
end

group :test do
  gem "govuk_test", "~> 1.0"
  gem "simplecov"
  gem "timecop"
end

group :development do
  gem "awesome_print"
  gem "listen", "~> 3.2"
  gem "pry-rails"
  gem "rubocop-govuk"
end
