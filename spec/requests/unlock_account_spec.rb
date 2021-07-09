RSpec.describe "Unlock account" do
  include ActiveJob::TestHelper

  let!(:user) { FactoryBot.create(:user) }

  before { clear_enqueued_jobs }

  context "getting an unlock email" do
    context "when the user's account gets locked" do
      before do
        user.lock_access!
      end

      it "sends the user a new confirmation email" do
        assert_enqueued_jobs 1, only: NotifyDeliveryJob
      end
    end

    context "when a locked user requests an unlock link" do
      before do
        user.lock_access!
        clear_enqueued_jobs
      end

      it "sends the user a new confirmation email" do
        request_unlock_link

        assert_enqueued_jobs 1, only: NotifyDeliveryJob
        expect(response.body).to have_content(I18n.t("devise.unlocks.send_instructions"))
      end
    end

    context "when an unlocked user requests an unlock link" do
      it "returns an error" do
        request_unlock_link

        expect(response.body).to have_content(I18n.t("errors.messages.not_locked"))
      end
    end
  end

  context "using an unlock email link" do
    context "when a locked user unlocks their account" do
      it "unlocks their account" do
        unlock_token = user.lock_access!
        click_unlock_link(unlock_token)

        user.reload

        expect(response.body).to have_content(I18n.t("devise.unlocks.unlocked"))
        expect(user.access_locked?).to be false
      end
    end

    context "when an unlocked and signed in user attempts to unlock their account" do
      it "redirects to their account" do
        sign_in user
        click_unlock_link("an-already-used-token")

        expect(response.body).not_to have_content(I18n.t("devise.unlocks.unlocked"))
      end
    end
  end

  def request_unlock_link
    post user_unlock_path, params: { user: { email: user.email } }
    follow_redirect!
  end

  def click_unlock_link(unlock_token)
    get user_unlock_path, params: { unlock_token: unlock_token }
    follow_redirect!
  end
end
