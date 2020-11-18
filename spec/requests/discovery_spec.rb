RSpec.describe "Doorkeeper::OpenidConnect::DiscoveryController" do
  let(:attribute_service_url) { "https://attribute-service" }

  around do |example|
    ClimateControl.modify(ATTRIBUTE_SERVICE_URL: attribute_service_url) do
      example.run
    end
  end

  it "includes the custom attribute service URL" do
    get "/.well-known/openid-configuration"
    expect(JSON.parse(response.body)).to include("userinfo_endpoint" => "#{attribute_service_url}/oidc/user_info")
  end
end
