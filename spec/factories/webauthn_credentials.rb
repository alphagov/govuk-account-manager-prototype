FactoryBot.define do
  factory :webauthn_credential do
    user
    sequence(:external_id) { |n| "external_id #{n}" }
    sequence(:public_key) { |n| "public_key #{n}" }
    sequence(:nickname) { |n| "nickname #{n}" }
    sign_count { 0 }
  end
end
