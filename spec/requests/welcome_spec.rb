RSpec.describe "welcome" do
  describe "GET" do
    it "redirects to registration page" do
      get welcome_path

      expect(response).to redirect_to(new_user_registration_start_path)
    end
  end

  context "the user is logged in" do
    let(:user) { FactoryBot.create(:user) }

    before do
      sign_in(user)
    end

    it "redirects the user to the account page" do
      get welcome_path

      expect(response).to redirect_to(user_root_path)
    end
  end
end
