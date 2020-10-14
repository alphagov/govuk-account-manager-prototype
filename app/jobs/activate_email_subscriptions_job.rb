class ActivateEmailSubscriptionsJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    User.find(user_id).email_subscriptions.find_each(&:activate_if_confirmed)
  end
end
