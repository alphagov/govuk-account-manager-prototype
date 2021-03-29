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

    trait :has_received_2021_03_survey do
      has_received_2021_03_survey { true }
    end

    trait :has_not_received_2021_03_survey do
      has_received_2021_03_survey { false }
    end
  end
end
