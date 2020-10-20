FactoryBot.define do
  factory :email_subscription do
    topic_slug { "transition checker emails" }
    subscription_id { "subscription-id" }
  end
end
