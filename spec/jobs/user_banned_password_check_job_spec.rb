RSpec.describe UserBannedPasswordCheckJob do
  let!(:user) { FactoryBot.create(:user) }

  before(:all) do
    BannedPassword.import_list(%w[banned-password])
  end

  context "user has a banned password" do
    before do
      user.update_attribute(:password, "banned-password") # rubocop:disable Rails/SkipsModelValidations
    end

    it "marks their password as banned" do
      UserBannedPasswordCheckJob.perform_now(user.id)

      expect(user.reload.banned_password_match).to be true
    end

    it "doesn't update the user if already checked" do
      user.update_attribute(:banned_password_match, false) # rubocop:disable Rails/SkipsModelValidations
      UserBannedPasswordCheckJob.perform_now(user.id)
      expect(user.reload.banned_password_match).to be false
    end
  end

  context "user does not have a banned password" do
    before do
      user.update_attribute(:password, "not-a-banned-password") # rubocop:disable Rails/SkipsModelValidations
    end

    it "marks their password as banned" do
      UserBannedPasswordCheckJob.perform_now(user.id)

      expect(user.reload.banned_password_match).to be false
    end
  end
end
