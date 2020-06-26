require "omniauth"
require "openid_connect"

class OmniAuth::Strategies::GovukOidc
  include OmniAuth::Strategy

  option :client_id
  option :client_secret
  option :idp_base_uri
  option :redirect_uri
  option :scope, "openid email"

  uid { @id_token.sub }

  info do
    {
      name: @user_info.name,
      email: @user_info.email,
    }
  end

  credentials do
    {
      id_token: @id_token,
      access_token: @access_token,
    }
  end

  extra { @user_info.as_json }

  delegate :authorization_endpoint,
           :token_endpoint,
           :userinfo_endpoint,
           :end_session_endpoint,
           to: :discover

  def request_phase
    nonce = SecureRandom.hex(16)
    redirect client.authorization_uri(
      scope: options.scope,
      state: nonce,
      nonce: nonce,
    )
  end

  def callback_phase
    code = request.params["code"]
    nonce = request.params["state"]

    client.authorization_code = code
    @access_token = client.access_token!
    @id_token = OpenIDConnect::ResponseObject::IdToken.decode @access_token.id_token, discover.jwks
    @id_token.verify! client_id: options.client_id, issuer: discover.issuer, nonce: nonce
    @user_info = @access_token.userinfo!

    super
  end

private

  def client
    @client ||= OpenIDConnect::Client.new(
      identifier: options.client_id,
      secret: options.client_secret,
      redirect_uri: options.redirect_uri,
      authorization_endpoint: authorization_endpoint,
      token_endpoint: token_endpoint,
      userinfo_endpoint: userinfo_endpoint,
    )
  end

  def discover
    @discover ||= OpenIDConnect::Discovery::Provider::Config.discover! options.idp_base_uri
  end
end
