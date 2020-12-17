FactoryBot.define do
  factory :user do
    email { "email@example.com" }
    password { "abcd1234" }
    phone { "+447958123456" }

    trait :confirmed do
      confirmed_at { Time.zone.now }
    end

    trait :email_change_requested do
      unconfirmed_email { "new_email@example.com" }
      confirmation_token { "abc123" }
    end
  end
end
