# frozen_string_literal: true

Rails.application.routes.draw do
  get "/register", to: "register#index"
  post "/register", to: "register#create"
end
