RSpec.describe ExpireJwtJob do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { FactoryBot.create(:user) }

  it "deletes hour-old state" do
    freeze_time do
      Jwt.create!(created_at: 61.minutes.ago, jwt_payload: "old", skip_parse_jwt_token: true)
      Jwt.create!(created_at: 30.minutes.ago, jwt_payload: "new", skip_parse_jwt_token: true)

      described_class.perform_now

      expect(Jwt.count).to eq(1)
      expect(Jwt.pluck(:jwt_payload)).to eq(%w[new])
    end
  end

  it "doesn't delete jwts attached to a RegistrationState" do
    freeze_time do
      jwt = Jwt.create!(created_at: 61.minutes.ago, jwt_payload: "old", skip_parse_jwt_token: true)
      RegistrationState.create!(
        state: :start,
        email: "email@example.com",
        jwt_id: jwt.id,
      )

      described_class.perform_now

      expect(Jwt.last).to eq(jwt)
    end
  end

  it "doesn't delete jwts attached to a LoginState" do
    freeze_time do
      jwt = Jwt.create!(created_at: 61.minutes.ago, jwt_payload: "old", skip_parse_jwt_token: true)
      LoginState.create!(
        created_at: Time.zone.now,
        user: user,
        redirect_path: "/",
        jwt_id: jwt.id,
      )

      described_class.perform_now

      expect(Jwt.last).to eq(jwt)
    end
  end
end
