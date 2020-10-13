class EmailSubscription < ApplicationRecord
  belongs_to :user

  before_destroy :deactivate_immediately

  def deactivate_immediately
    return unless subscription_id

    Services.email_alert_api.unsubscribe(subscription_id)
  end
end
