FactoryBot.define do
  factory :security_activity do
    event_type { 1 }
    created_at { "2020-07-09 16:53:09" }
    client_id { "MyString" }
    ip_address { "MyString" }
  end

  factory :data_activity do
  end
end
