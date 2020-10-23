class SecurityController < ApplicationController
  before_action :authenticate_user!

  def show
    @activity = current_user.security_activities.order(created_at: :desc)
    @data_exchanges = current_user
      .data_activities
      .order(created_at: :desc)
      .map { |a| activity_to_exchange(a) }
      .compact
  end

  def report; end

private

  def activity_to_exchange(activity)
    return if activity.oauth_application == AccountManagerApplication.application

    scopes = activity.scopes.split(" ").map(&:to_sym) - ScopeDefinition.new.hidden_scopes
    return if scopes.empty?

    {
      application_name: activity.oauth_application.name,
      created_at: activity.created_at,
      scopes: scopes,
    }
  end
end
