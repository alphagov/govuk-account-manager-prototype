RSpec.describe ExpireRegistrationStateJob do
  include ActiveSupport::Testing::TimeHelpers

  it "deletes old state" do
    freeze_time do
      RegistrationState.create!(updated_at: (RegistrationState::EXPIRATION_AGE + 1.minute).ago, email: "old", state: :start)
      RegistrationState.create!(updated_at: RegistrationState::EXPIRATION_AGE.ago, email: "new", state: :start)

      expect { described_class.perform_now }.to(change { RegistrationState.expired.count })

      expect(RegistrationState.pluck(:email)).to eq(%w[new])
    end
  end
end
