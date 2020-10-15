FactoryBot.define do
  factory :application_key do
    application_uid { "test-id" }
    key_id { "00000000-0000-0000-0000-000000000000" }
    pem { "public_key" }

    trait :transition_checker do
      application_uid { "transition-checker-id" }
      key_id { "898d62b7-eed9-464a-a4ae-9d9e08bd9bee" }
      pem { "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEjMgE/d6Bdu1K17BTjNycDvIXKSmU\ngZ5YYoayU3gGqTLhgefuK2qbo99Wx+SuvdW/GRvIlUIW1ooNRdQ3QFwwCw==\n-----END PUBLIC KEY-----\n" }
    end
  end
end
