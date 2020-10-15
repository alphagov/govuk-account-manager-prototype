module FeaturesHelper
  def jwt_private_key
    private_key = OpenSSL::PKey::EC.new "prime256v1" # pragma: allowlist secret
    private_key.generate_key
    private_key
  end

  def jwt_public_key(private_key)
    OpenSSL::PKey::EC.new private_key
  end

  def transition_jwt_key_id
    "898d62b7-eed9-464a-a4ae-9d9e08bd9bee"
  end

  def transition_uuid
    "transition-checker-id"
  end

  def transition_jwt_scopes
    %i[email openid transition_checker]
  end

  def transition_jwt_attributes
    {
      "transition_checker_state": {
        "criteria_keys": %w[
          living-ie
        ],
        "timestamp": 1_602_772_468,
        "email_topic_slug": "get-ready-for-2021",
      },
    }
  end

  def transition_jwt_post_login_oauth
    "http://localhost/oauth/authorize?client_id=transition-checker-id&nonce=d0ab9d9c92ba4f5497c1aad570eef427&redirect_uri=http%3A%2F%2Ffinder-frontend.dev.gov.uk%2Ftransition-check%2Flogin%2Fcallback&response_type=code&scope=transition_checker%20openid&state=d0ab9d9c92ba4f5497c1aad570eef427%3A%2Ftransition-check%2Fsave-your-results%2Fconfirm%3Fc%255B%255D%3Dliving-ie"
  end

  def transition_payload
    {
      uid: transition_uuid,
      key: transition_jwt_key_id,
      scopes: transition_jwt_scopes,
      attributes: transition_jwt_attributes,
      post_login_oauth: transition_jwt_post_login_oauth,
    }.compact
  end

  def post_jwt_to_root(transition_payload, _public_key)
    page.driver.post new_user_session_path(
      jwt: valid_signup_jwt(
        transition_payload,
        private_key,
      ),
    )
  end

  def valid_signup_jwt(payload, private_key)
    JWT.encode payload.compact, private_key, "ES256"
  end

  def register_authorised_application(public_key)
    FactoryBot.create(:doorkeeper_application, :transition_checker)
    FactoryBot.create(:application_key, :transition_checker, pem: public_key.to_pem)
  end
end
