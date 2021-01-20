RSpec.describe ExpireEphemeralStateJob do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { FactoryBot.create(:user) }

  it "deletes old state" do
    freeze_time do
      EphemeralState.create!(created_at: (EphemeralState::EXPIRATION_AGE + 1.minute).ago, user_id: user.id, token: "old")
      EphemeralState.create!(created_at: EphemeralState::EXPIRATION_AGE.ago, user_id: user.id, token: "new")

      expect { described_class.perform_now }.to(change { EphemeralState.expired.count })

      expect(EphemeralState.pluck(:token)).to eq(%w[new])
    end
  end
end
