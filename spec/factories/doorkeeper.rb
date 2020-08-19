FactoryBot.define do
  factory :oauth_application, class: Doorkeeper::Application do
  end

  factory :oauth_access_token, class: Doorkeeper::AccessToken do
  end

  factory :oauth_access_grant, class: Doorkeeper::AccessGrant do
  end
end
