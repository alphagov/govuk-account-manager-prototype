RSpec.describe "welcome" do
  it "presents the permissions-policy header" do
    get welcome_path
    expect(response.headers["Permissions-Policy"]).to eq("interest-cohort=()")
  end

  it "redirects to /sign-in" do
    get welcome_path
    expect(response).to redirect_to(new_user_session_path)
  end

  context "the user is logged in" do
    let(:user) { FactoryBot.create(:user) }

    before { sign_in(user) }

    it "redirects to /account/home on GOV.UK" do
      get welcome_path
      expect(response).to redirect_to(user_root_path_on_govuk)
    end
  end
end
