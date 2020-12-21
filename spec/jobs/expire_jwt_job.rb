RSpec.describe ExpireJwtJob do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { FactoryBot.create(:user) }

  it "deletes hour-old state" do
    freeze_time do
      Jwt.create!(created_at: 61.minutes.ago, jwt_payload: "old")
      Jwt.create!(created_at: 30.minutes.ago, jwt_payload: "new")

      described_class.perform_now

      expect(Jwt.count).to eq(1)
      expect(Jwt.pluck(:jwt_payload)).to eq(%w[/new])
    end
  end
end
