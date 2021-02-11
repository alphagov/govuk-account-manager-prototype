FactoryBot.define do
  factory :webauthn_credential do
    user
    external_id { "123" }
    public_key { "blah" }
    nickname { "test_webauthn_cred" }
    sign_count { 0 }
  end
end
