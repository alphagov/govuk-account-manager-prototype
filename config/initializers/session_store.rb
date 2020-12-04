GovukAccountManagerPrototype::Application.config.session_store :cookie_store,
                                                               key: "_govuk_account_manager_prototype_session",
                                                               expire_after: 30.minutes,
                                                               same_site: :lax,
                                                               secure: Rails.env.production?
