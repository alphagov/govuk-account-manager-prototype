# frozen_string_literal: true

source "https://rubygems.org"

ruby File.read(".ruby-version").strip

gem "bootsnap", ">= 1.4.2"
gem "keycloak-admin", "0.7.5"
gem "openid_connect"
gem "puma", "~> 4.1"
gem "rails", "~> 6.0.3", ">= 6.0.3.1"
gem "sass-rails", ">= 6"

group :development, :test do
  gem "byebug"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "rspec-rails"
end

group :development do
  gem "awesome_print"
  gem "listen", "~> 3.2"
  gem "rubocop-govuk"
  gem "pry-rails"
end
