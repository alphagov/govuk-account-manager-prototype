class EmailSubscription < ApplicationRecord
  belongs_to :user

  before_destroy :deactivate_immediately

  def reactivate_if_confirmed
    return if migrated_to_account_api
    return unless user.confirmed?

    deactivate_immediately

    subscriber_list = Services.email_alert_api.get_subscriber_list(slug: topic_slug)

    subscription = Services.email_alert_api.subscribe(
      subscriber_list_id: subscriber_list.to_hash.dig("subscriber_list", "id"),
      address: user.email,
      frequency: "daily",
      skip_confirmation_email: true,
    )

    update!(subscription_id: subscription.to_hash.dig("subscription", "id"))
  end

  def deactivate_immediately
    return unless subscription_id

    Services.email_alert_api.unsubscribe(subscription_id)
  rescue GdsApi::HTTPGone, GdsApi::HTTPNotFound
    # this can happen if the subscription has been deactivated by the
    # user through email-alert-frontend
  end
end
