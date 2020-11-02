# frozen_string_literal: true

module ApplicationHelper
  def date_with_time_ago(datetime)
    "#{datetime.strftime('%d %B %Y at %H:%M')} (#{time_ago_in_words(datetime)} ago)"
  end

  def navigation_items
    if user_signed_in?
      [
        {
          text: t("navigation.user_root_path"),
          href: user_root_path,
          active: true,
          sub_menu: "account-navigation-list",
        },
        {
          text: t("navigation.destroy_user_session"),
          href: destroy_user_session_path,
        },
      ]
    else
      []
    end
  end

  def has_criteria_keys?(registration_state)
    return false if registration_state.blank?

    registration_state.jwt_payload&.dig("attributes", "transition_checker_state", "criteria_keys").present?
  end

  def email_alerts_only_path(registration_state)
    checker_results = registration_state.jwt_payload&.dig("attributes", "transition_checker_state", "criteria_keys")
    checker_results_query = { c: checker_results }.to_query
    email_signup_path = "/email-signup"
    "#{transition_checker_path}#{email_signup_path}?#{checker_results_query}"
  end

  def transition_checker_path
    base_url = Rails.env.development? ? Plek.find("finder-frontend") : Plek.new.website_root
    "#{base_url}/transition-check"
  end

  def transition_path
    base_url = Rails.env.development? ? Plek.find("collections") : Plek.new.website_root
    "#{base_url}/transition"
  end
end
