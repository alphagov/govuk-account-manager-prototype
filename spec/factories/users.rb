FactoryBot.define do
  factory :user do
    email { "email@example.com" }
    password { "abcd1234" }
    password_confirmation { "abcd1234" }
    phone { "+447958123456" }

    factory :confirmed_user do
      confirmed_at { Time.zone.now }
    end
  end
end
