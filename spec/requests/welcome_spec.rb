RSpec.describe "welcome" do
  it "redirects to /sign-in" do
    get welcome_path
    expect(response).to redirect_to(new_user_session_path)
  end

  context "the user is logged in" do
    let(:user) { FactoryBot.create(:user) }

    before { sign_in(user) }

    it "redirects to /account" do
      get welcome_path
      expect(response).to redirect_to(user_root_path)
    end
  end
end
