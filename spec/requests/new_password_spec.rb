RSpec.describe "new-password" do
  include ActiveJob::TestHelper

  describe "GET" do
    it "renders the form" do
      get new_user_password_path

      expect(response.body).to have_content(I18n.t("devise.passwords.new.title"))
    end
  end

  describe "POST" do
    let(:params) do
      {
        "user[email]" => user.email,
      }
    end

    let(:user) do
      u = FactoryBot.create(
        :user,
        email: "user@domain.tld",
        password: "breadbread1",
        password_confirmation: "breadbread1",
      )
      # clear confirmation email job
      clear_enqueued_jobs
      u
    end

    it "sends an email" do
      post account_password_path, params: params

      follow_redirect!

      expect(response).to be_successful

      assert_enqueued_jobs 1, only: NotifyDeliveryJob
    end
  end
end
