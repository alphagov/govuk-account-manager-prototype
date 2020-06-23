# frozen_string_literal: true

Rails.application.routes.draw do
  get "/register", to: "register#show"
  post "/register", to: "register#create"

  mount GovukPublishingComponents::Engine, at: "/component-guide" if Rails.env.development?

  get "/", to: "welcome#show"

  get "/manage", to: "manage#show"

  get "/callback", to: "callback#show"

  get "/confirm-email", to: "email_confirmation#confirm_email"
  get "/resend-confirmation", to: "email_confirmation#resend_confirmation"

  get "/reset-password", to: "reset_password#show"
  post "/reset-password", to: "reset_password#submit"

  get "/new-password", to: "new_password#show"
  post "/new-password", to: "new_password#submit"

  get "/logout", to: "logout#show"
end
