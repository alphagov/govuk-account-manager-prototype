class RemoteUserInfo
  def self.call(user)
    new(user).user_info
  end

  def initialize(user)
    @user = user
  end

  def user_info
    uri = "#{ENV['ATTRIBUTE_SERVICE_URL']}/oidc/user_info"
    response = with_retries do
      RestClient.get uri, { accept: :json, authorization: "Bearer #{token.token}" }
    end
    JSON.parse(response.body).deep_symbolize_keys
  rescue StandardError => e
    Raven.capture_exception(e)
    nil
  end

  def update_profile!
    with_retries do
      RestClient.post(
        "#{ENV['ATTRIBUTE_SERVICE_URL']}/v1/attributes",
        { attributes: { email: @user.email.to_json, email_verified: @user.confirmed?.to_json } },
        { accept: :json, authorization: "Bearer #{token.token}" },
      )
    end
  end

  def destroy!
    with_retries do
      RestClient.delete(
        "#{ENV['ATTRIBUTE_SERVICE_URL']}/v1/attributes/all",
        { accept: :json, authorization: "Bearer #{token.token}" },
      )
    end
  end

  def token
    @token ||= AccountManagerApplication.user_token(@user.id)
  end

protected

  def with_retries(attempts = 3)
    yield
  rescue RestClient::Exceptions::Timeout, RestClient::ServerBrokeConnection, RestClient::BadGateway, RestClient::GatewayTimeout => e
    attempts -= 1
    retry unless attempts.zero?

    raise e
  end
end
