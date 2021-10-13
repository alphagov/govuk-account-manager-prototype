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
    GovukError.notify(e)
    nil
  end

  def update_profile!
    with_retries do
      attributes = {
        email: @user.email,
        email_verified: @user.confirmed?,
        has_unconfirmed_email: !@user.unconfirmed_email.nil?,
      }

      RestClient.post(
        "#{ENV['ATTRIBUTE_SERVICE_URL']}/v1/attributes",
        { attributes: attributes.transform_values(&:to_json) },
        { accept: :json, authorization: "Bearer #{token.token}" },
      )

      GdsApi.account_api.update_user_by_subject_identifier(
        subject_identifier: @user.generate_subject_identifier,
        cookie_consent: @user.cookie_consent,
        feedback_consent: @user.feedback_consent,
        **attributes,
      )
    end
  end

  def destroy!
    with_retries { delete_attribute_store_data }
    with_retries { delete_user_data_in_account_api }
  end

  def token
    @token ||= AccountManagerApplication.user_token(@user.id)
  end

protected

  def with_retries(attempts = 3)
    yield
  rescue RestClient::Exceptions::Timeout,
         RestClient::ServerBrokeConnection,
         RestClient::BadGateway,
         RestClient::GatewayTimeout,
         GdsApi::TimedOutException,
         GdsApi::HTTPIntermittentServerError => e
    attempts -= 1
    retry unless attempts.zero?

    raise e
  end

  def delete_attribute_store_data
    RestClient.delete(
      "#{ENV['ATTRIBUTE_SERVICE_URL']}/v1/attributes/all",
      { accept: :json, authorization: "Bearer #{token.token}" },
    )
  end

  def delete_user_data_in_account_api
    GdsApi.account_api.delete_user_by_subject_identifier(
      subject_identifier: @user.generate_subject_identifier,
    )
  end
end
