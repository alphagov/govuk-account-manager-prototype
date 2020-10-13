class EmailSubscription < ApplicationRecord
  belongs_to :user

  before_destroy :deactivate_immediately

  def activate_if_confirmed
    return if subscription_id
    return unless user.confirmed?

    subscriber_list = Services.email_alert_api.get_subscriber_list(slug: topic_slug)

    Services.email_alert_api.subscribe(
      subscriber_list_id: subscriber_list.to_hash.dig("subscriber_list", "id"),
      address: user.email,
      frequency: "daily",
    )
  end

  def deactivate_immediately
    return unless subscription_id

    Services.email_alert_api.unsubscribe(subscription_id)
  end
end
