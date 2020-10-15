FactoryBot.define do
  factory :doorkeeper_application, class: Doorkeeper::Application do
    name { "Test Application" }
    redirect_uri { "http://test.dev.gov.uk/callback" }
    scopes { %w[openid] }
    uid { "test-id" }
    secret { "test-secret" }

    trait :transition_checker do
      name { "Transition Checker" }
      redirect_uri { "http://finder-frontend.dev.gov.uk/transition-check/login/callback" }
      scopes { %w[email openid transition_checker] }
      uid { "transition-checker-id" }
      secret { "transition-checker-secret" }
    end
  end
end
