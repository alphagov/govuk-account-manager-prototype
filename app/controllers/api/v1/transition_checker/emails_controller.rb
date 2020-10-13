class Api::V1::TransitionChecker::EmailsController < Doorkeeper::ApplicationController
  before_action -> { doorkeeper_authorize! :transition_checker }

  def show
    user = User.find(doorkeeper_token.resource_owner_id)
    subscription = user.email_subscriptions.first

    head 404 and return unless subscription
    head 200 and return unless subscription.subscription_id

    begin
      state = Services.email_alert_api.get_subscription(subscription.subscription_id)
      has_ended = state.to_hash.dig("subscription", "ended_reason")
      head has_ended ? 410 : 200
    rescue GdsApi::HTTPGone, GdsApi::HTTPNotFound
      head 410
    end
  end
end
