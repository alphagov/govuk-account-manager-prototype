RSpec.describe ExpireRegistrationStateJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  it "deletes hour-old state" do
    freeze_time do
      RegistrationState.create!(touched_at: 61.minutes.ago, email: "old", state: :start)
      RegistrationState.create!(touched_at: 30.minutes.ago, email: "new", state: :start)

      described_class.perform_now

      expect(RegistrationState.count).to eq(1)
      expect(RegistrationState.pluck(:email)).to eq(%w[new])
    end
  end
end
