RSpec.describe Report::Accounts do
  let(:report) { described_class.new(user_id_pepper: "pepper").all }

  context "with no users" do
    it "returns []" do
      expect(report).to eq([])
    end
  end

  context "with users" do
    it "excludes the smokey user" do
      FactoryBot.create(:user, email: Report::SMOKEY_USER)
      expect(report).to eq([])
    end

    it "#in_batches" do
      FactoryBot.create(:user, email: "foo@example.com", cookie_consent: false, feedback_consent: true)
      FactoryBot.create(:user, email: "bar@example.com", cookie_consent: true, feedback_consent: false)

      batched_report = []

      described_class.new(user_id_pepper: "pepper").in_batches(batch_size: 1) do |rows|
        expect(rows.length).to eq(1)
        batched_report.concat(rows)
      end

      expect(batched_report).to eq(report)
    end

    it "finds all the users" do
      u1 = FactoryBot.create(:user, email: "foo@example.com", cookie_consent: false, feedback_consent: true)
      u2 = FactoryBot.create(:user, email: "bar@example.com", cookie_consent: true, feedback_consent: false)

      expect(report.count).to eq(2)
      expect(report.map { |e| e[:user_id] }.uniq.count).to eq(2)
      expect(report.map { |e| e[:registration_timestamp] }).to eq([u1, u2].map(&:created_at))
      expect(report.map { |e| e[:cookie_consent] }).to eq([u1, u2].map(&:cookie_consent))
      expect(report.map { |e| e[:feedback_consent] }).to eq([u1, u2].map(&:feedback_consent))
    end

    it "hashes the user IDs" do
      u = FactoryBot.create(:user, email: "foo@example.com", cookie_consent: false, feedback_consent: true)

      expect(report[0][:user_id]).to_not eq(u.id)
    end
  end
end
