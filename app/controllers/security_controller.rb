class SecurityController < ApplicationController
  before_action :authenticate_user!

  SUMMARY_ACTIVITIES_TO_SHOW = 3

  def show
    @activity = current_user.security_activities.show_on_security_page.order(created_at: :desc).limit(SUMMARY_ACTIVITIES_TO_SHOW).map(&:fill_missing_country)
    @data_exchanges = dedup_nearby(current_user.data_activities.where.not(oauth_application_id: AccountManagerApplication.application.id).order(created_at: :desc))
      .compact
      .map { |a| activity_to_exchange(a) }
      .compact
  end

  def report; end

  def paginated_activity
    page_number = params[:page_number].to_i
    user_activity = current_user.security_activities.show_on_security_page.order(created_at: :desc).page(page_number)

    @activity = user_activity
    @activity_with_country = user_activity.map(&:fill_missing_country)

    unless user_activity.out_of_range?
      @page_navigation = {}

      unless user_activity.first_page?
        @page_navigation[:previous_page] = {
          url: account_security_paginated_path(page_number: @activity.prev_page),
          title: t("account.security.page_numbering_previous"),
          label: t("account.security.page_numbering_navigation", target_page: @activity.prev_page, total_pages: @activity.total_pages),
        }
      end

      unless user_activity.last_page?
        @page_navigation[:next_page] = {
          url: account_security_paginated_path(page_number: @activity.next_page),
          title: t("account.security.page_numbering_next"),
          label: t("account.security.page_numbering_navigation", target_page: @activity.next_page, total_pages: @activity.total_pages),
        }
      end
    end
  end

private

  def dedup_nearby(activities)
    last_activity = nil
    activities.map do |activity|
      if last_activity.nil? || !activity.very_similar_to(last_activity)
        last_activity = activity
        activity
      end
    end
  end

  def activity_to_exchange(activity)
    scopes = activity.scopes.split(" ").map(&:to_sym) - ScopeDefinition.new.hidden_scopes

    {
      application_name: activity.oauth_application.name,
      created_at: activity.created_at,
      scopes: scopes,
    }
  end
end
