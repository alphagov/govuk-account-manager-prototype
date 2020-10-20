RSpec.describe ExpireLoginStateJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) do
    FactoryBot.create(
      :user,
      email: "email@example.com",
      password: "abcd1234", # pragma: allowlist secret
      password_confirmation: "abcd1234",
    )
  end

  it "deletes hour-old state" do
    freeze_time do
      LoginState.create!(created_at: 61.minutes.ago, user_id: user.id, redirect_path: "/old")
      LoginState.create!(created_at: 30.minutes.ago, user_id: user.id, redirect_path: "/new")

      described_class.perform_now

      expect(LoginState.count).to eq(1)
      expect(LoginState.pluck(:redirect_path)).to eq(%w[/new])
    end
  end
end
