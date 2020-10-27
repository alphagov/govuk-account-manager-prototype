RSpec.describe "logout" do
  include ActiveJob::TestHelper

  let(:user) { FactoryBot.create(:user) }

  before { sign_in(user) }

  describe "GET" do
    it "refreshes the salt" do
      old_salt = user.authenticatable_salt
      get destroy_user_session_path
      expect(user.reload.authenticatable_salt).to_not eq(old_salt)
    end
  end
end
