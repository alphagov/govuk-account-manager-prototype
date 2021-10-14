RSpec.describe "/account/edit/consent" do
  before do
    sign_in FactoryBot.create(:user)
  end

  context "updating cookie consent" do
    it "creates a job to update the remote user info" do
      post edit_user_consent_cookie_path, params: { cookie_consent: "yes" }
      assert_enqueued_jobs 1, only: UpdateRemoteUserInfoJob
    end
  end

  context "updating feedback consent" do
    it "creates a job to update the remote user info" do
      post edit_user_consent_feedback_path, params: { feedback_consent: "yes" }
      assert_enqueued_jobs 1, only: UpdateRemoteUserInfoJob
    end
  end
end
