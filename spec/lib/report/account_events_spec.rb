RSpec.describe Report::AccountEvents do
  let(:report) { described_class.new(start_date: start_date, end_date: end_date, user_id_pepper: "pepper").all.sort_by { |e| e[:login_timestamp] } }

  let(:start_date) { Time.zone.local(2020, 1, 22, 10, 0, 0) }
  let(:end_date) { start_date + 1.day }

  context "with no login events" do
    it "returns []" do
      expect(report).to eq([])
    end
  end

  context "with events in the period" do
    let(:smokey_user) { FactoryBot.create(:user, email: Report::SMOKEY_USER) }
    let(:user1) { FactoryBot.create(:user, email: "foo@example.com") }
    let(:user2) { FactoryBot.create(:user, email: "bar@example.com") }

    it "excludes the smokey user" do
      create_login_event(smokey_user, start_date)
      expect(report).to eq([])
    end

    it "#in_batches" do
      create_login_event(user1, start_date + 59.minutes)
      create_login_event(user1, start_date + 60.minutes)
      create_login_event(user1, start_date + 120.minutes)

      batched_report = []

      described_class.new(start_date: start_date, end_date: end_date, user_id_pepper: "pepper").in_batches(batch_size: 1) do |rows|
        expect(rows.length).to eq(1)
        batched_report.concat(rows)
      end

      expect(batched_report).to eq(report)
    end

    it "finds all the events" do
      e1 = create_login_event(user2, start_date + 59.minutes)
      e2 = create_login_event(user1, start_date + 60.minutes)
      e3 = create_login_event(user1, start_date + 120.minutes)
      e4 = create_login_event(user2, start_date + 121.minutes)
      e5 = create_login_event(user2, start_date + 149.minutes)
      e6 = create_login_event(user1, start_date + 150.minutes)
      e7 = create_login_event(user1, start_date + 180.minutes + Report::AccountEvents::SESSION_DURATION)
      e8 = create_login_event(user2, start_date + 181.minutes + Report::AccountEvents::SESSION_DURATION)

      expect(report.count).to eq(8)
      expect(report.map { |e| e[:user_id] }.uniq.count).to eq(2)
      expect(report.map { |e| e[:login_timestamp] }).to eq([e1, e2, e3, e4, e5, e6, e7, e8].map(&:created_at))
      expect(report.map { |e| e[:login_type] }).to eq(%i[account account session session session session returning returning])
    end

    it "hashes the user IDs" do
      e = create_login_event(user1, start_date + 60.minutes)

      expect(report.first[:user_id]).to_not eq(e.user_id)
    end

    context "with events before the period" do
      it "uses the previous login time" do
        create_login_event(user1, start_date - Report::AccountEvents::SESSION_DURATION)
        create_login_event(user2, start_date - 10.minutes)

        e1 = create_login_event(user2, start_date + 59.minutes)
        e2 = create_login_event(user1, start_date + 60.minutes)
        e3 = create_login_event(user1, start_date + 120.minutes)
        e4 = create_login_event(user2, start_date + 121.minutes)
        e5 = create_login_event(user2, start_date + 149.minutes)
        e6 = create_login_event(user1, start_date + 150.minutes)
        e7 = create_login_event(user1, start_date + 180.minutes + Report::AccountEvents::SESSION_DURATION)
        e8 = create_login_event(user2, start_date + 181.minutes + Report::AccountEvents::SESSION_DURATION)

        expect(report.count).to eq(8)
        expect(report.map { |e| e[:user_id] }.uniq.count).to eq(2)
        expect(report.map { |e| e[:login_timestamp] }).to eq([e1, e2, e3, e4, e5, e6, e7, e8].map(&:created_at))
        expect(report.map { |e| e[:login_type] }).to eq(%i[session returning session session session session returning returning])
      end
    end
  end

  def create_login_event(user, created_at)
    SecurityActivity.create!(
      event_type: SecurityActivity::LOGIN_SUCCESS.id,
      user_id: user.id,
      ip_address: "127.0.0.1",
      created_at: created_at,
      updated_at: created_at,
    )
  end
end
