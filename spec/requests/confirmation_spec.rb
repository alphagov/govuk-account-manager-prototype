RSpec.describe "/account/confirmation" do
  let(:user) { FactoryBot.create(:user) }

  it "creates a job to update the remote user info" do
    get user_confirmation_path(confirmation_token: user.confirmation_token)
    assert_enqueued_jobs 1, only: UpdateRemoteUserInfoJob
  end
end
