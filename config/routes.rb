# frozen_string_literal: true

Rails.application.routes.draw do
  use_doorkeeper
  use_doorkeeper_openid_connect

  devise_for :users, skip: :all
  devise_scope :user do
    get  "/login", to: "devise/sessions#new", as: :new_user_session
    post "/login", to: "devise/sessions#create", as: :user_session
    get  "/logout", to: "devise/sessions#destroy", as: :destroy_user_session

    get   "/account/password/new", to: "devise_passwords#new", as: :new_user_password
    get   "/account/password/edit", to: "devise_passwords#edit", as: :edit_user_password
    patch "/account/password", to: "devise_passwords#update", as: :user_password
    put   "/account/password", to: "devise_passwords#update"
    post  "/account/password", to: "devise_passwords#create", as: :create_password
    get   "/account/reset-password", to: "devise_passwords#new", as: :reset_password
    get   "/account/reset-password-sent", to: "devise_passwords#sent", as: :reset_password_sent

    get  "/new-account", to: "devise_registration#new", as: :new_user_registration
    post "/new-account", to: "devise_registration#create", as: :new_user_registration_post
    get  "/new-account/cancel", to: "devise_registration#cancel", as: :cancel_user_registration
    get  "/new-account/welcome", to: "post_registration#show", as: :new_user_after_sign_up

    get    "/account/manage", to: "devise_registration#edit", as: :edit_user_registration
    patch  "/account", to: "devise_registration#update", as: :user_registration
    put    "/account", to: "devise_registration#update"
    delete "/account", to: "devise_registration#destroy"

    get "/account/confirmation-email-sent", to: "devise_registration#confirmation_email_sent"

    get  "/account/confirmation/new", to: "devise/confirmations#new", as: :new_user_confirmation
    get  "/account/confirmation", to: "devise/confirmations#show", as: :user_confirmation
    post "/account/confirmation", to: "devise_confirmations#create"
    get  "/account/confirmation-sent", to: "devise_confirmations#sent", as: :confirmation_sent

    get  "/account/unlock/new", to: "devise/unlocks#new", as: :new_user_unlock
    get  "/account/unlock", to: "devise/unlocks#show", as: :user_unlock
    post "/account/unlock", to: "devise/unlocks#create"
  end

  mount GovukPublishingComponents::Engine, at: "/component-guide" if Rails.env.development?

  get "/", to: "welcome#show"

  get "/account", to: "account#show", as: :user_root

  scope "/account" do
    get "/activity", to: "activity#show"
    get "/your-data", to: "data_exchange#show"
    get "/profile", to: "profile#show"
  end

  scope "/api" do
    scope "/v1" do
      get "/deanonymise-tokens", to: "api_deanonymise_tokens#show"
    end
  end
end
