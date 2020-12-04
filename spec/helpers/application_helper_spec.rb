RSpec.describe ApplicationHelper do
  include ActiveSupport::Testing::TimeHelpers

  describe "#date_with_time_ago" do
    it "displays one minute ago for time in last minute" do
      travel_to Time.zone.local(2020, 1, 22, 10, 0, 0) do
        expect(date_with_time_ago(Time.zone.local(2020, 1, 22, 9, 59, 0))).to eq("22 January 2020 at 09:59 (1 minute ago)")
      end
    end

    it "displays minutes ago for time in last hour" do
      travel_to Time.zone.local(2020, 1, 22, 10, 0, 0) do
        expect(date_with_time_ago(Time.zone.local(2020, 1, 22, 9, 57, 0))).to eq("22 January 2020 at 09:57 (3 minutes ago)")
      end
    end

    it "displays hours ago for time in last day" do
      travel_to Time.zone.local(2020, 1, 22, 10, 0, 0) do
        expect(date_with_time_ago(Time.zone.local(2020, 1, 22, 8, 57, 0))).to eq("22 January 2020 at 08:57 (about 1 hour ago)")
      end
    end

    it "displays days ago for time in last month" do
      travel_to Time.zone.local(2020, 1, 22, 10, 0, 0) do
        expect(date_with_time_ago(Time.zone.local(2020, 1, 10, 9, 59, 0))).to eq("10 January 2020 at 09:59 (12 days ago)")
      end
    end

    it "displays months ago for time in last year" do
      travel_to Time.zone.local(2020, 1, 22, 10, 0, 0) do
        expect(date_with_time_ago(Time.zone.local(2019, 11, 10, 9, 59, 0))).to eq("10 November 2019 at 09:59 (2 months ago)")
      end
    end

    it "displays years ago for time over one year ago" do
      travel_to Time.zone.local(2020, 1, 22, 10, 0, 0) do
        expect(date_with_time_ago(Time.zone.local(2017, 1, 22, 9, 59, 0))).to eq("22 January 2017 at 09:59 (about 3 years ago)")
      end
    end

    it "copes with DST starting" do
      travel_to Time.zone.local(2020, 10, 25, 2, 0, 0) do
        expect(date_with_time_ago(Time.zone.local(2020, 10, 25, 1, 0, 0))).to eq("25 October 2020 at 01:00 (about 2 hours ago)")
      end
    end

    it "copes with DST ending" do
      travel_to Time.zone.local(2020, 3, 29, 2, 0, 0) do
        expect(date_with_time_ago(Time.zone.local(2020, 3, 29, 1, 0, 0))).to eq("29 March 2020 at 02:00 (less than a minute ago)")
      end
    end
  end

  describe "#service_for" do
    let(:user) { FactoryBot.create(:user) }

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
      expect(service_for(url, user)[:name]).to eq(application.name)
    end

    it "only produces a service name if the link looks like an OAuth content URL" do
      url = "//nefarious-attempt-to-embed-an-arbitrary-link?" + Rack::Utils.build_nested_query(client_id: application.uid)
      expect(service_for(url, user)).to be_nil
    end

    context "the client_id doesn't match an application" do
      it "returns nil" do
        url = oauth_authorization_path + "?" + Rack::Utils.build_nested_query(client_id: "breadbread")
        expect(service_for(url, user)).to be_nil
      end
    end
  end
end
