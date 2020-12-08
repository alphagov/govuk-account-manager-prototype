RSpec.describe ExpireEphemeralStateJob do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { FactoryBot.create(:user) }

  it "deletes hour-old state" do
    freeze_time do
      EphemeralState.create!(created_at: 61.minutes.ago, user_id: user.id, token: "old")
      EphemeralState.create!(created_at: 30.minutes.ago, user_id: user.id, token: "new")

      described_class.perform_now

      expect(EphemeralState.count).to eq(1)
      expect(EphemeralState.pluck(:token)).to eq(%w[new])
    end
  end
end
