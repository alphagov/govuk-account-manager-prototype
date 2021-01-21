RSpec.describe ExpireJwtJob do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { FactoryBot.create(:user) }

  it "deletes old state" do
    freeze_time do
      Jwt.create!(created_at: (Jwt::EXPIRATION_AGE + 1.minute).ago, jwt_payload: "old", skip_parse_jwt_token: true)
      Jwt.create!(created_at: Jwt::EXPIRATION_AGE.ago, jwt_payload: "new", skip_parse_jwt_token: true)

      expect { described_class.perform_now }.to(change { Jwt.expired.count })

      expect(Jwt.pluck(:jwt_payload)).to eq(%w[new])
    end
  end
end
