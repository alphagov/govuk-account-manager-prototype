FactoryBot.define do
  factory :registration_state do
    id { "7216ddfe-d225-4d28-8989-36734bb4c2cd" }
    email { "test@gov.uk" }
    password { "parrot_ranger_boiler_tsunami" }

    trait :finished do
      yes_to_emails { true }
      cookie_consent { true }
      feedback_consent { true }
      touched_at { Time.zone.now }
      state { "finish" }
    end
  end
end
