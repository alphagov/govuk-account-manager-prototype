# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, skip: :all
  devise_scope :user do
    get "/", to: "welcome#show", as: :welcome

    get "/feedback", to: "feedback#show", as: :feedback_form
    post "/feedback", to: "feedback#submit", as: :feedback_form_submitted

    scope "/sign-in" do
      get  "/", to: "sessions#create", as: :new_user_session
      post "/", to: "sessions#create"
      get  "/phone/code", to: "sessions#phone_code", as: :user_session_phone_code
      post "/phone/verify", to: "sessions#phone_verify", as: :user_session_phone_verify
      get  "/phone/resend", to: "sessions#phone_resend", as: :user_session_phone_resend
      post "/phone/resend", to: "sessions#phone_resend_code"
    end

    get "/sign-out", to: "sessions#destroy", as: :destroy_user_session

    get "/login", to: redirect(path: "/sign-in")
    get "/logout", to: redirect(path: "/sign-out")

    scope "/account" do
      get "/insecure-password", to: "insecure_password#show", as: :insecure_password_interstitial

      get "/manage", to: "manage#show", as: :account_manage
      get "/security", to: "security#show", as: :account_security
      get "/security/activity/:page_number", to: "security#paginated_activity", as: :account_security_paginated_activity
      get "/security/code/:page_number", to: "security#paginated_mfa_tokens", as: :account_security_paginated_mfa_tokens

      get    "/delete", to: "delete#show", as: :account_delete
      delete "/delete", to: "delete#destroy"
      get    "/delete/confirmation", to: "delete#confirmation", as: :account_delete_confirmation

      get   "/", to: "account#show"
      patch "/", to: "registrations#update", as: :user_registration
      put   "/", to: "registrations#update"

      scope "/mfa" do
        get "/abort", to: "redo_mfa#stop", as: :redo_mfa_stop

        scope "/phone" do
          get  "/code", to: "redo_mfa_phone#code", as: :redo_mfa_phone_code
          post "/verify", to: "redo_mfa_phone#verify", as: :redo_mfa_phone_verify
          get  "/resend", to: "redo_mfa_phone#resend", as: :redo_mfa_phone_resend
          post "/resend", to: "redo_mfa_phone#resend_code"
        end
      end

      scope "/edit" do
        get  "/email", to: "registrations#edit_email", as: :edit_user_registration_email
        get  "/password", to: "registrations#edit_password", as: :edit_user_registration_password

        scope "/phone" do
          get  "/", to: "edit_phone#show", as: :edit_user_registration_phone
          get "/new", to: "edit_phone#new", as: :edit_user_registration_phone_new
          post "/confirm", to: "edit_phone#confirm", as: :edit_user_registration_phone_confirm
          get  "/code", to: "edit_phone#code", as: :edit_user_registration_phone_code
          post "/code", to: "edit_phone#code_send"
          post "/verify", to: "edit_phone#verify", as: :edit_user_registration_phone_verify
          get  "/resend", to: "edit_phone#resend", as: :edit_user_registration_phone_resend
        end

        scope "/consent" do
          get  "/cookie", to: "edit_consent#cookie", as: :edit_user_consent_cookie
          post "/cookie", to: "edit_consent#cookie_send"
          get  "/feedback", to: "edit_consent#feedback", as: :edit_user_consent_feedback
          post "/feedback", to: "edit_consent#feedback_send"
        end
      end

      scope "/password" do
        patch "/", to: "passwords#update", as: :user_password
        put   "/", to: "passwords#update"
        post  "/", to: "passwords#create", as: :create_password

        get "/new", to: "passwords#new", as: :new_user_password
        get "/edit", to: "passwords#edit", as: :edit_user_password

        scope "/reset" do
          get "/", to: "passwords#new", as: :reset_password
          get "/sent", to: "passwords#sent", as: :reset_password_sent
        end
      end

      scope "/confirmation" do
        get  "/", to: "confirmations#show", as: :user_confirmation
        post "/", to: "confirmations#create"

        get "/new", to: "confirmations#new", as: :new_user_confirmation
        get "/sent", to: "confirmations#sent", as: :confirmation_email_sent
      end

      scope "/unlock" do
        get  "/", to: "unlocks#show", as: :user_unlock
        post "/", to: "unlocks#create"
        get  "/new", to: "unlocks#new", as: :new_user_unlock
      end
    end

    scope "/new-account" do
      get  "/", to: "registrations#start", as: :new_user_registration_start
      post "/", to: "registrations#start"
      get  "/phone/code", to: "registrations#phone_code", as: :new_user_registration_phone_code
      post "/phone/verify", to: "registrations#phone_verify", as: :new_user_registration_phone_verify
      get  "/phone/resend", to: "registrations#phone_resend", as: :new_user_registration_phone_resend
      post "/phone/resend", to: "registrations#phone_resend_code"
      get  "/your-information", to: "registrations#your_information", as: :new_user_registration_your_information
      post "/your-information", to: "registrations#your_information_post"
      get  "/transition-emails", to: "registrations#transition_emails", as: :new_user_registration_transition_emails
      post "/transition-emails", to: "registrations#transition_emails_post"
      get  "/finish", to: "registrations#create", as: :new_user_registration_finish
      get  "/cancel", to: "registrations#cancel", as: :cancel_user_registration

      get "/welcome", to: redirect(path: "/sign-in")
    end
  end

  namespace :api do
    namespace :v1 do
      get "/deanonymise-token", to: "deanonymise_token#show"
      get "/ephemeral-state", to: "ephemeral_state#show"

      post "/jwt", to: "jwt#create"

      scope "transition-checker", module: :transition_checker, as: :transition_checker do
        get "/email-subscription", to: "emails#show"
        post "/email-subscription", to: "emails#update"
        delete "/email-subscription", to: "emails#destroy"
      end

      namespace :report do
        get "/general", to: "general#show"

        post "/bigquery", to: "bigquery#create"
      end
    end
  end

  mount GovukPublishingComponents::Engine, at: "/component-guide" if Rails.env.development?

  use_doorkeeper
  use_doorkeeper_openid_connect

  get "/404", to: "standard_errors#not_found"
  get "/429", to: "standard_errors#too_many_requests"
  get "/422", to: "standard_errors#unprocessable_entity"
  get "/500", to: "standard_errors#internal_server_error"

  get "/healthcheck", to: "healthcheck#show"

  if Rails.env.test?
    get "/account/home", to: proc { [200, {}, ["fake account dashboard page for feature tests"]] }
  end
end
