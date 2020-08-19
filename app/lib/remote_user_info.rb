class RemoteUserInfo
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

  def destroy!
    RestClient.delete(
      "#{ENV['ATTRIBUTE_SERVICE_URL']}/v1/attributes/all",
      { accept: :json, authorization: "Bearer #{token.token}" },
    )
  end

  def token
    @token ||= AccountManagerApplication.user_token(@user.id)
  end
end
