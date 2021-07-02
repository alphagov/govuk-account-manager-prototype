class Api::V1::TransitionChecker::EmailsController < Doorkeeper::ApplicationController
  skip_before_action :verify_authenticity_token

  before_action -> { doorkeeper_authorize! :transition_checker }

  rescue_from ActionController::ParameterMissing do
    head :bad_request
  end

  def show
    user = User.find(doorkeeper_token.resource_owner_id)
    subscription = user.email_subscriptions.first

    head :not_found and return unless subscription
    head :not_found and return if subscription.migrated_to_account_api

    if subscription.subscription_id.nil?
      render json: subscription_hash(subscription)
      return
    end

    begin
      state = Services.email_alert_api.get_subscription(subscription.subscription_id)
      if state.to_hash.dig("subscription", "ended_reason")
        head :gone
      else
        render json: subscription_hash(subscription)
      end
    rescue GdsApi::HTTPGone, GdsApi::HTTPNotFound
      head :gone
    end
  end

  def update
    topic_slug = params.fetch(:topic_slug)

    subscription = EmailSubscription.transaction { find_and_update_subscription(topic_slug) }
    head :not_found and return unless subscription

    render json: subscription_hash(subscription)
  end

  def destroy
    user = User.find(doorkeeper_token.resource_owner_id)
    subscription = user.email_subscriptions.first

    if subscription
      subscription.update!(migrated_to_account_api: true)
      head :no_content
    else
      head :not_found
    end
  end

private

  def find_and_update_subscription(topic_slug)
    user = User.find(doorkeeper_token.resource_owner_id)
    subscription = user.email_subscriptions.first

    if subscription
      return nil if subscription.migrated_to_account_api
      return subscription if subscription&.topic_slug == topic_slug

      subscription.update!(topic_slug: topic_slug)
    else
      subscription = EmailSubscription.create!(
        user_id: user.id,
        topic_slug: topic_slug,
      )
    end

    subscription.reactivate_if_confirmed
    subscription
  end

  def subscription_hash(subscription)
    {
      topic_slug: subscription.topic_slug,
      email_alert_api_subscription_id: subscription.subscription_id,
    }
  end
end
