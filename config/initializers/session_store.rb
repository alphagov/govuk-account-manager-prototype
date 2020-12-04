GovukAccountManagerPrototype::Application.config.session_store :cookie_store,
                                                               key: "_govuk_account_manager_prototype_session",
                                                               secure: Rails.env.production?
