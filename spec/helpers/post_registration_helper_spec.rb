RSpec.describe PostRegistrationHelper, type: :helper do
  describe "#service_name_for" do
    let(:application) do
      FactoryBot.create(
        :oauth_application,
        name: "Some Other Government Service",
        redirect_uri: "https://www.gov.uk",
        scopes: [],
      )
    end

    it "extracts the service name using the client_id parameter" do
      url = oauth_authorization_path + "?" + Rack::Utils.build_nested_query(client_id: application.uid)
      expect(service_name_for(url)).to eq(application.name)
    end

    it "only produces a service name if the link looks like an OAuth content URL" do
      url = "//nefarious-attempt-to-embed-an-arbitrary-link?" + Rack::Utils.build_nested_query(client_id: application.uid)
      expect(service_name_for(url)).to be_nil
    end

    context "the client_id doesn't match an application" do
      it "returns nil" do
        url = oauth_authorization_path + "?" + Rack::Utils.build_nested_query(client_id: "breadbread")
        expect(service_name_for(url)).to be_nil
      end
    end
  end
end
