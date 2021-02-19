class SecurityController < ApplicationController
  before_action :authenticate_user!

  SUMMARY_ACTIVITIES_TO_SHOW = 3
  SECURITY_CODES_TO_SHOW = 3
  SECURITY_KEYS_TO_SHOW = 3

  def show
    @activity = current_user
      .security_activities
      .show_on_security_page
      .order(created_at: :desc)
      .limit(SUMMARY_ACTIVITIES_TO_SHOW)
      .map(&:fill_missing_country)

    @data_exchanges = DataActivity
      .select("DISTINCT on (oauth_application_id) *")
      .includes([:oauth_application])
      .where(user: current_user)
      .where.not(oauth_application_id: AccountManagerApplication.application.id)
      .order(oauth_application_id: :desc, created_at: :desc)
      .map { |a| activity_to_exchange(a) }
      .sort_by { |a| a[:created_at] }
      .reverse

    @mfa_tokens = current_user
      .mfa_tokens
      .order(created_at: :desc)
      .limit(SECURITY_CODES_TO_SHOW)

    @regisered_security_keys = current_user
      .webauthn_credentials
      .order(created_at: :desc)
      .limit(SECURITY_KEYS_TO_SHOW)
  end

  def report; end

  def paginated_activity
    page_number = params[:page_number].to_i
    @activity = current_user.security_activities.show_on_security_page.order(created_at: :desc).page(page_number)
    @activity_with_country = @activity.map(&:fill_missing_country)
  end

  def paginated_mfa_tokens
    page_number = params[:page_number].to_i
    @mfa_tokens = current_user.mfa_tokens.order(created_at: :desc).page(page_number)
  end

private

  def activity_to_exchange(activity)
    scopes = activity.scopes.split(" ").map(&:to_sym) - ScopeDefinition.new.hidden_scopes

    {
      application_name: activity.oauth_application.name,
      created_at: activity.created_at,
      scopes: scopes,
    }
  end
end
