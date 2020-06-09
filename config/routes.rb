# frozen_string_literal: true

Rails.application.routes.draw do
  get "/register", to: "register#show"
  post "/register", to: "register#create"

  mount GovukPublishingComponents::Engine, at: "/component-guide" if Rails.env.development?

  get "/manage", to: "manage#show"

  get "/callback", to: "callback#show"

  get "/verify", to: "verify#show"

  get "/logout", to: "logout#show"
end
