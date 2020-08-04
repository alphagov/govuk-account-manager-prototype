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
    JSON.parse(response.body).deep_symbolize_keys.merge(basic_user_info)
  rescue StandardError => e
    Raven.capture_exception(e)
    basic_user_info
  end

  def basic_user_info
    {
      email_address: @user.email,
    }
  end

  def token
    @token ||= Doorkeeper::AccessToken.transaction do
      application = find_application
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

  def find_application
    Doorkeeper::Application.find_by(name: "GOV.UK Account Manager")
  end
end
