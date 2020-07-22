RSpec.describe ApplicationHelper, type: :helper do
  describe "#date_with_time_ago" do
    it "displays one minute ago for time in last minute" do
      Timecop.freeze("2020-07-22 10:00:00") do
        expect(date_with_time_ago(1595411952000)).to eq("22 July 2020 at 09:59 (1 minute ago)")
      end
    end

    it "displays minutes ago for time in last hour" do
      Timecop.freeze("2020-07-22 10:00:00") do
        expect(date_with_time_ago(1595411832000)).to eq("22 July 2020 at 09:57 (3 minutes ago)")
      end
    end

    it "displays hours ago for time in last day" do
      Timecop.freeze("2020-07-22 10:00:00") do
        expect(date_with_time_ago(1595408232000)).to eq("22 July 2020 at 08:57 (about 1 hour ago)")
      end
    end

    it "displays days ago for time in last month" do
      Timecop.freeze("2020-07-22 10:00:00") do
        expect(date_with_time_ago(1594375152000)).to eq("10 July 2020 at 09:59 (12 days ago)")
      end
    end

    it "displays months ago for time in last year" do
      Timecop.freeze("2020-07-22 10:00:00") do
        expect(date_with_time_ago(1578650352000)).to eq("10 January 2020 at 09:59 (6 months ago)")
      end
    end

    it "displays years ago for time over one year ago" do
      Timecop.freeze("2020-07-22 10:00:00") do
        expect(date_with_time_ago(1497952752000)).to eq("20 June 2017 at 09:59 (about 3 years ago)")
      end
    end
  end
end
