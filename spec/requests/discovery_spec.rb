RSpec.describe "Doorkeeper::OpenidConnect::DiscoveryController", type: :request do
  let(:attribute_service_url) { "https://attribute-service" }

  before do
    ENV["ATTRIBUTE_SERVICE_URL"] = attribute_service_url
  end

  it "includes the custom attribute service URL" do
    get "/.well-known/openid-configuration"
    expect(JSON.parse(response.body)).to include("userinfo_endpoint" => "#{attribute_service_url}/oidc/user_info")
  end
end
