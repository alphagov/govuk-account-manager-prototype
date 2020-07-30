FactoryBot.define do
  factory :oauth_application, class: Doorkeeper::Application do
    id            { 1 }
    uid           { "8AGx4q2ltTBJU0KPlbOzjdWsmm3k80VVNkKjwGkcS1U" }
    secret        { "SlRdBYZV7TB7PbktkQnHibXvyv2g2uNj3XeQjSa0gJA" }
    confidential  { true }

    factory :email_alert_api, class: Doorkeeper::Application do
      name          { "Email Alert API" }
      redirect_uri  { "http://localhost:3000/auth/email-subscriptions/callback" }
      scopes        { :"emailsubscriptions.read_only" }
    end
  end

  factory :oauth_access_token, class: Doorkeeper::AccessToken do
  end
end
