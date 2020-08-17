class RemoteUserInfo
  TOKEN_SCOPES = %i[account_manager_access].freeze

  def self.call(user)
    new(user).user_info
  end

  def initialize(user)
    @user = user
  end

  def user_info
    uri = "#{ENV['ATTRIBUTE_SERVICE_URL']}/oidc/user_info"
    response = RestClient.get uri, { accept: :json, authorization: "Bearer #{token.token}" }
    JSON.parse(response.body).deep_symbolize_keys
  rescue StandardError => e
    Raven.capture_exception(e)
    nil
  end

  def update_profile!
    RestClient.put(
      "#{ENV['ATTRIBUTE_SERVICE_URL']}/v1/attributes/email",
      { value: @user.email.to_json },
      { accept: :json, authorization: "Bearer #{token.token}" },
    )
    RestClient.put(
      "#{ENV['ATTRIBUTE_SERVICE_URL']}/v1/attributes/email_verified",
      { value: @user.confirmed?.to_json },
      { accept: :json, authorization: "Bearer #{token.token}" },
    )
  end

  def token
    @token ||= Doorkeeper::AccessToken.transaction do
      application = AccountManagerApplication.fetch
      token = find_token(application)
      token.nil? ? create_token(application) : token
    end
  end

private

  def find_token(application)
    Doorkeeper::AccessToken.matching_token_for(
      application,
      @user.id,
      Doorkeeper::OAuth::Scopes.from_array(TOKEN_SCOPES),
    )
  end

  def create_token(application)
    Doorkeeper::AccessToken.create!(
      application_id: application.id,
      resource_owner_id: @user.id,
      scopes: TOKEN_SCOPES,
    )
  end
end
