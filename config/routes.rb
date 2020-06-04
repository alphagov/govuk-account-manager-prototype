# frozen_string_literal: true

Rails.application.routes.draw do
  get "/register", to: "register#show"
  post "/register", to: "register#create"

  get "/manage", to: "manage#show"

  get "/callback", to: "callback#show"
end
