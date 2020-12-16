RSpec.describe UrlHelper do
  describe "#add_param_to_url" do
    it "returns the url unchanged if the value is missing" do
      expect(add_param_to_url("http://www.example.com", "foo", "")).to eq("http://www.example.com")
    end

    it "uses a ? if the url doesn't already have a query string" do
      expect(add_param_to_url("http://www.example.com", "foo", "bar")).to eq("http://www.example.com?foo=bar")
    end

    it "uses a & if the url already has a query string" do
      expect(add_param_to_url("http://www.example.com?1=2", "foo", "bar")).to eq("http://www.example.com?1=2&foo=bar")
    end
  end
end
