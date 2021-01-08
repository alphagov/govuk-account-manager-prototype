RSpec.describe "login" do
  let!(:user) { FactoryBot.create(:user, banned_password_match: nil) }

  it "sets the banned_password_match field to false" do
    post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password }
    expect(user.reload.banned_password_match).to be(false)
  end

  context "the password is banned" do
    before { BannedPassword.import_list([user.password]) }

    it "sets the banned_password_match field to true" do
      post new_user_session_path, params: { "user[email]" => user.email, "user[password]" => user.password }
      expect(user.reload.banned_password_match).to be(true)
    end
  end
end
