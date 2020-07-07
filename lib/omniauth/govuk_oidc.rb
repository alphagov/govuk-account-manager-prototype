require "omniauth"
require "openid_connect"
require "services"

class OmniAuth::Strategies::GovukOidc
  include OmniAuth::Strategy

  option :client_id
  option :client_secret
  option :redirect_uri
  option :scope, "openid email"
  option :return_to_prefix, "/"
  option :return_to_default, "/"

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

  extra { @user_info.as_json.merge(return_to: @return_to) }

  def request_phase
    nonce = SecureRandom.hex(16)
    return_to = request.params.fetch("return_to", "/")
    redirect client.authorization_uri(
      scope: options.scope,
      state: "#{nonce}:#{return_to}",
      nonce: nonce,
    ).sub(Services.discover.authorization_endpoint, "/login")
  end

  def callback_phase
    code = request.params["code"]
    state = request.params["state"].split(":")
    nonce = state[0]
    return_to = state[1]
    @return_to = return_to.starts_with?(options.return_to_prefix) ? return_to : options.return_to_default

    client.authorization_code = code
    @access_token = client.access_token!
    @id_token = OpenIDConnect::ResponseObject::IdToken.decode @access_token.id_token, Services.discover.jwks
    @id_token.verify! client_id: options.client_id, issuer: Services.discover.issuer, nonce: nonce
    @user_info = @access_token.userinfo!

    super
  end

private

  def client
    @client ||= OpenIDConnect::Client.new(
      identifier: options.client_id,
      secret: options.client_secret,
      redirect_uri: options.redirect_uri,
      authorization_endpoint: Services.discover.authorization_endpoint,
      token_endpoint: Services.discover.token_endpoint,
      userinfo_endpoint: Services.discover.userinfo_endpoint,
    )
  end
end
