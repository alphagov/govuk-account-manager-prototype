RSpec.describe "welcome" do
  include ActiveJob::TestHelper

  let(:actual_reset_password_token) { user.send_reset_password_instructions }

  describe "GET" do
    it "renders the email address form" do
      get new_user_session_url

      expect(response.body).to have_content(I18n.t("welcome.show.heading"))
    end

    context "email address given" do
      context "the user exists" do
        let!(:user) do
          FactoryBot.create(
            :user,
            email: "user@domain.tld",
            password: "breadbread1",
            password_confirmation: "breadbread1",
          )
        end

        it "shows the login form" do
          get new_user_session_url(user: { email: user.email })

          expect(response.body).to have_content(I18n.t("devise.sessions.new.heading"))
        end
      end

      context "the user doesn't exist" do
        it "shows the registration form" do
          get new_user_session_url(user: { email: "no-such-user@domain.tld" })

          expect(response.body).to have_content(I18n.t("devise.registrations.new.heading"))
        end
      end
    end
  end

  context "the user is logged in" do
    let(:user) do
      FactoryBot.create(
        :user,
        email: "user@domain.tld",
        password: "breadbread1",
        password_confirmation: "breadbread1",
      )
    end

    before do
      sign_in(user)
    end

    it "redirects the user to the account page" do
      get new_user_session_url

      expect(response).to redirect_to(user_root_path)
    end
  end
end
