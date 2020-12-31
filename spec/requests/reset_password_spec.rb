RSpec.describe "resetting a password" do
  include ActiveJob::TestHelper

  let!(:user) { FactoryBot.create(:user) }

  describe "password reset form" do
    it "renders the form" do
      get new_user_password_path

      expect(response.body).to have_content(I18n.t("change_password.heading"))
    end
  end

  describe "request reset token" do
    before { clear_enqueued_jobs }

    it "sends an email" do
      post create_password_path, params: { "user[email]" => user.email }
      follow_redirect!

      expect(response).to be_successful

      assert_enqueued_jobs 1, only: NotifyDeliveryJob
    end
  end

  describe "use reset token" do
    context "when the password is on the denylist" do
      let(:password) { "some-banned-password" } # pragma: allowlist secret

      before do
        BannedPassword.import_list([password])
      end

      it "returns an error" do
        post user_password_path, params: {
          "_method" => "put",
          "user[password]" => password,
          "user[password_confirmation]" => password,
          "user[reset_password_token]" => user.send_reset_password_instructions,
        }

        expect(response.body).to have_content(Rails::Html::FullSanitizer.new.sanitize(I18n.t("activerecord.errors.models.user.attributes.password.denylist")))
      end
    end
  end
end
