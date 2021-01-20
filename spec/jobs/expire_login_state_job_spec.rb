RSpec.describe ExpireLoginStateJob do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { FactoryBot.create(:user) }

  it "deletes old state" do
    freeze_time do
      LoginState.create!(created_at: (LoginState::EXPIRATION_AGE + 1.minute).ago, user_id: user.id, redirect_path: "/old")
      LoginState.create!(created_at: LoginState::EXPIRATION_AGE.ago, user_id: user.id, redirect_path: "/new")

      expect { described_class.perform_now }.to(change { LoginState.expired.count })

      expect(LoginState.pluck(:redirect_path)).to eq(%w[/new])
    end
  end
end
