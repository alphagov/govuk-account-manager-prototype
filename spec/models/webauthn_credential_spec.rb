RSpec.describe WebauthnCredential do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "factories" do
    it "has a valid factory" do
      expect(FactoryBot.build(:user)).to be_valid
    end

    it "has a valid factory" do
      user = FactoryBot.build(:user, :with_webauthn_credentials)
      credentials = user.webauthn_credentials

      expect(user).to be_valid
      credentials.each { |credential| expect(credential).to be_valid }
    end
  end
end
