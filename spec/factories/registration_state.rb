FactoryBot.define do
  factory :registration_state do
    id { "7216ddfe-d225-4d28-8989-36734bb4c2cd" }
    email { "test@gov.uk" }
    encrypted_password { "parrot_ranger_boiler_tsunami" }
    phone { "+447958123456" }

    trait :finished do
      yes_to_emails { true }
      cookie_consent { true }
      feedback_consent { true }
      state { "finish" }
    end
  end
end
