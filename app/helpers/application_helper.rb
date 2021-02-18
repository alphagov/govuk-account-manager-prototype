# frozen_string_literal: true

require "cgi"

module ApplicationHelper
  def humanized_date(datetime)
    datetime.strftime("%d %B %Y")
  end

  def date_with_time_ago(datetime)
    "#{datetime.strftime('%d %B %Y at %H:%M')} (#{time_ago_in_words(datetime)} ago)"
  end

  def redacted_phone_number(phone_number)
    formatted_number = MultiFactorAuth.formatted_phone_number(phone_number)
    prefix = formatted_number[0..-4].gsub(/[^\s]/, "x")
    suffix = formatted_number[-3..]
    "#{prefix}#{suffix}"
  end

  def navigation_items
    if user_signed_in?
      [
        {
          text: t("navigation.user_root_path"),
          href: user_root_path,
          active: true,
        },
        {
          text: t("navigation.destroy_user_session"),
          href: destroy_user_session_path,
        },
      ]
    else
      []
    end
  rescue Devise::MissingWarden
    # Since we render the 429 page directly from the rack-attack
    # middleware, there is no warden in the env, so Devise throws an
    # error.  Treat this the same as being logged out.
    []
  end

  def show_confirmation_reminder?
    return false unless current_user

    !current_user.confirmed_at? || current_user.unconfirmed_email?
  end

  def confirmed_user_changed_email?
    return false unless current_user

    current_user.confirmed_at? && current_user.unconfirmed_email?
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

  def service_for(previous_url)
    return unless previous_url&.start_with? oauth_authorization_path

    bits = previous_url.split("?")
    return unless bits.length > 1

    querystring = CGI.parse(bits[1])
    return unless querystring["client_id"]

    app = Doorkeeper::Application.by_uid(querystring["client_id"].first)
    return unless app

    {
      name: app.name,
      url: previous_url,
    }
  end

  def footer_navigation
    navigation = []
    t("footer_sections").each do |section|
      nav_section = section
      nav_section[:items] = []
      section[:links].each do |link|
        item = link
        # use link text for data-track-label unless a different label is specified
        item[:attributes][:data][:track_label] = link[:attributes][:data][:track_label] || link[:text]
        nav_section[:items] << item
      end

      navigation << nav_section
    end

    navigation
  end

  def footer_meta
    meta = { items: [] }
    t("footer_meta").each do |link|
      meta[:items] << link
    end

    meta
  end
end
