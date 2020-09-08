# frozen_string_literal: true

Rails.application.routes.draw do
  get "/", to: "welcome#show"

  devise_for :users, skip: :all
  devise_scope :user do
    get  "/login", to: "devise/sessions#new", as: :new_user_session
    post "/login", to: "devise/sessions#create", as: :user_session
    get  "/logout", to: "devise/sessions#destroy", as: :destroy_user_session

    scope "/account" do
      get    "/", to: "account#show", as: :user_root
      patch  "/", to: "devise_registration#update", as: :user_registration
      put    "/", to: "devise_registration#update"
      delete "/", to: "devise_registration#destroy"

      get "/activity", to: "activity#show"
      get "/your-data", to: "data_exchange#show"
      get "/profile", to: "profile#show"
      get "/manage", to: "devise_registration#edit", as: :edit_user_registration

      scope "/password" do
        patch "/", to: "devise_passwords#update", as: :user_password
        put   "/", to: "devise_passwords#update"
        post  "/", to: "devise_passwords#create", as: :create_password

        get "/new", to: "devise_passwords#new", as: :new_user_password
        get "/edit", to: "devise_passwords#edit", as: :edit_user_password
      end

      get "/reset-password", to: "devise_passwords#new", as: :reset_password
      get "/reset-password-sent", to: "devise_passwords#sent", as: :reset_password_sent

      scope "/confirmation" do
        get  "/", to: "devise/confirmations#show", as: :user_confirmation
        post "/", to: "devise_confirmations#create"

        get "/new", to: "devise/confirmations#new", as: :new_user_confirmation
        get "/sent", to: "devise_registration#confirmation_email_sent", as: :confirmation_email_sent
      end

      scope "/unlock" do
        get  "/", to: "devise/unlocks#show", as: :user_unlock
        post "/", to: "devise/unlocks#create"
        get  "/new", to: "devise/unlocks#new", as: :new_user_unlock
      end
    end

    scope "/new-account" do
      get  "/", to: "devise_registration#new", as: :new_user_registration
      post "/", to: "devise_registration#create", as: :new_user_registration_post
      get  "/cancel", to: "devise_registration#cancel", as: :cancel_user_registration
      get  "/welcome", to: "post_registration#show", as: :new_user_after_sign_up
    end
  end

  scope "/api" do
    scope "/v1" do
      get "/deanonymise-token", to: "api_deanonymise_token#show"
      post "/register-client", to: "api_register_client#create"
    end
  end

  mount GovukPublishingComponents::Engine, at: "/component-guide" if Rails.env.development?

  use_doorkeeper
  use_doorkeeper_openid_connect

  get "/404", to: "standard_errors#not_found"
  get "/422", to: "standard_errors#unprocessable_entity"
  get "/500", to: "standard_errors#internal_server_error"
end
