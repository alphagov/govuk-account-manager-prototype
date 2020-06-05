require "openid_connect"

class OIDCClient
  def initialize(provider_uri, client_id, secret, redirect_uri)
    @provider_uri = provider_uri
    @client_id = client_id
    @secret = secret
    @redirect_uri = redirect_uri
  end

  def auth_uri(nonce)
    client.authorization_uri(
      scope: %i[profile email],
      state: nonce,
      nonce: nonce,
    )
  end

  def handle_redirect(code, nonce)
    client.authorization_code = code
    access_token = client.access_token!
    id_token = OpenIDConnect::ResponseObject::IdToken.decode access_token.id_token, discover.jwks
    id_token.verify! client_id: @client_id, issuer: discover.issuer, nonce: nonce
    user_info = access_token.userinfo!

    {
      access_token: access_token,
      id_token: id_token,
      user_info: user_info,
    }
  end

private

  def client
    @client ||= OpenIDConnect::Client.new(
      identifier: @client_id,
      secret: @secret,
      redirect_uri: @redirect_uri,
      authorization_endpoint: discover.authorization_endpoint,
      token_endpoint: discover.token_endpoint,
      userinfo_endpoint: discover.userinfo_endpoint,
    )
  end

  def discover
    @discover ||= OpenIDConnect::Discovery::Provider::Config.discover! @provider_uri
  end
end
