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

    {
      access_token: access_token,
      id_token: id_token,
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

# make http work
module OpenIDConnect
  module Discovery
    module Provider
      class Config
        class Resource
          def initialize(uri)
            @host = uri.host
            @port = uri.port unless [80, 443].include?(uri.port)
            @path = File.join uri.path, ".well-known/openid-configuration"
            @scheme = uri.scheme
            attr_missing!
          end

          def endpoint
            SWD.url_builder = case @scheme
                              when "http"
                                URI::HTTP
                              else
                                URI::HTTPS
                              end
            SWD.url_builder.build [nil, host, port, path, nil, nil]
          rescue URI::Error => e
            raise SWD::Exception, e.message
          end
        end
      end
    end
  end
end
