# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, skip: :all
  devise_scope :user do
    get  "/", to: "welcome#show", as: :new_user_session
    post "/", to: "welcome#show"

    get "/feedback", to: "feedback#show", as: :feedback_form
    post "/feedback", to: "feedback#submit", as: :feedback_form_submitted

    scope "/login" do
      get  "/", to: "devise_sessions#create", as: :user_session
      post "/", to: "devise_sessions#create"
      get  "/phone/code", to: "devise_sessions#phone_code", as: :user_session_phone_code
      post "/phone/code", to: "devise_sessions#phone_code_send"
      post "/phone/verify", to: "devise_sessions#phone_verify", as: :user_session_phone_verify
      get  "/phone/resend", to: "devise_sessions#phone_resend", as: :user_session_phone_resend
    end

    get "/logout", to: "devise_sessions#destroy", as: :destroy_user_session

    scope "/account" do
      get "/manage", to: "manage#show", as: :account_manage
      get "/security", to: "security#show", as: :account_security
      get "/security/report", to: "security#report", as: :account_security_report

      get    "/delete", to: "delete#show", as: :account_delete
      delete "/delete", to: "delete#destroy"
      get    "/delete/confirmation", to: "delete#confirmation", as: :account_delete_confirmation

      get   "/", to: "account#show", as: :user_root
      patch "/", to: "devise_registration#update", as: :user_registration
      put   "/", to: "devise_registration#update"

      scope "/edit" do
        get  "/email", to: "devise_registration#edit_email", as: :edit_user_registration_email
        get  "/password", to: "devise_registration#edit_password", as: :edit_user_registration_password

        scope "/phone" do
          get  "/", to: "edit_phone#show", as: :edit_user_registration_phone
          get  "/code", to: "edit_phone#code", as: :edit_user_registration_phone_code
          post "/code", to: "edit_phone#code_send"
          post "/verify", to: "edit_phone#verify", as: :edit_user_registration_phone_verify
          get  "/resend", to: "edit_phone#resend", as: :edit_user_registration_phone_resend
          get  "/done", to: "edit_phone#done", as: :edit_user_registration_phone_done
        end

        scope "/consent" do
          get  "/cookie", to: "edit_consent#cookie", as: :edit_user_consent_cookie
          post "/cookie", to: "edit_consent#cookie_send"
          get  "/feedback", to: "edit_consent#feedback", as: :edit_user_consent_feedback
          post "/feedback", to: "edit_consent#feedback_send"
        end
      end

      scope "/password" do
        patch "/", to: "devise_passwords#update", as: :user_password
        put   "/", to: "devise_passwords#update"
        post  "/", to: "devise_passwords#create", as: :create_password

        get "/new", to: "devise_passwords#new", as: :new_user_password
        get "/edit", to: "devise_passwords#edit", as: :edit_user_password

        scope "/reset" do
          get "/", to: "devise_passwords#new", as: :reset_password
          get "/sent", to: "devise_passwords#sent", as: :reset_password_sent
        end
      end

      scope "/confirmation" do
        get  "/", to: "devise_confirmations#show", as: :user_confirmation
        post "/", to: "devise_confirmations#create"

        get "/new", to: "devise_confirmations#new", as: :new_user_confirmation
        get "/sent", to: "devise_registration#confirmation_email_sent", as: :confirmation_email_sent
      end

      scope "/unlock" do
        get  "/", to: "devise/unlocks#show", as: :user_unlock
        post "/", to: "devise/unlocks#create"
        get  "/new", to: "devise/unlocks#new", as: :new_user_unlock
      end
    end

    scope "/new-account" do
      get  "/", to: "devise_registration#start", as: :new_user_registration_start
      post "/", to: "devise_registration#start"
      get  "/phone", to: "devise_registration#phone", as: :new_user_registration_phone
      get  "/phone/code", to: "devise_registration#phone_code", as: :new_user_registration_phone_code
      post "/phone/code", to: "devise_registration#phone_code_send"
      post "/phone/verify", to: "devise_registration#phone_verify", as: :new_user_registration_phone_verify
      get  "/phone/resend", to: "devise_registration#phone_resend", as: :new_user_registration_phone_resend
      get  "/your-information", to: "devise_registration#your_information", as: :new_user_registration_your_information
      post "/your-information", to: "devise_registration#your_information_post"
      get  "/transition-emails", to: "devise_registration#transition_emails", as: :new_user_registration_transition_emails
      post "/transition-emails", to: "devise_registration#transition_emails_post"
      get  "/finish", to: "devise_registration#create", as: :new_user_registration_finish
      get  "/cancel", to: "devise_registration#cancel", as: :cancel_user_registration
      get  "/welcome", to: "post_registration#show", as: :new_user_after_sign_up
    end
  end

  namespace :api do
    namespace :v1 do
      get "/deanonymise-token", to: "deanonymise_token#show"
      post "/register-client", to: "register_client#create"

      scope "transition-checker", module: :transition_checker, as: :transition_checker do
        get "/email-subscription", to: "emails#show"
        post "/email-subscription", to: "emails#update"
      end
    end
  end

  mount GovukPublishingComponents::Engine, at: "/component-guide" if Rails.env.development?

  use_doorkeeper
  use_doorkeeper_openid_connect

  get "/404", to: "standard_errors#not_found"
  get "/422", to: "standard_errors#unprocessable_entity"
  get "/500", to: "standard_errors#internal_server_error"

  get "/healthcheck", to: "healthcheck#show"
end
