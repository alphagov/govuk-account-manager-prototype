class SecurityController < ApplicationController
  before_action :authenticate_user!

  def show
    @activity = current_user.security_activities.order(created_at: :desc)
    @data_exchanges = dedup_nearby(current_user.data_activities.where.not(oauth_application_id: AccountManagerApplication.application.id).order(created_at: :desc))
      .compact
      .map { |a| activity_to_exchange(a) }
      .compact
  end

  def report; end

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
