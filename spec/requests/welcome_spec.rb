RSpec.describe "welcome" do
  describe "GET" do
    it "renders the email address form" do
      get new_user_session_url

      expect(response.body).to have_content(I18n.t("welcome.show.heading"))
    end

    context "email address given" do
      context "the user exists" do
        let!(:user) { FactoryBot.create(:user) }

        it "redirects to the login form" do
          get new_user_session_url(user: { email: user.email })
          follow_redirect!

          expect(response.body).to have_content(I18n.t("devise.sessions.new.heading"))
        end
      end

      context "the user doesn't exist" do
        before { allow(Rails.configuration).to receive(:force_jwt_at_registration).and_return(false) }

        it "redirects to the registration form" do
          get new_user_session_url(user: { email: "no-such-user@domain.tld" })
          follow_redirect!

          expect(response.body).to have_content(I18n.t("devise.registrations.start.fields.password.label"))
        end
      end
    end
  end

  context "the user is logged in" do
    let(:user) { FactoryBot.create(:user) }

    before do
      sign_in(user)
    end

    it "redirects the user to the account page" do
      get new_user_session_url

      expect(response).to redirect_to(user_root_path)
    end
  end
end
