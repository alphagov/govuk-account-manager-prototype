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

    trait :with_webauthn_credentials do
      transient do
        credentials_count { 2 }
      end

      after(:create) do |user, evaluator|
        create_list(:webauthn_credential, evaluator.credentials_count, user: user)
        user.reload
      end
    end
  end
end
