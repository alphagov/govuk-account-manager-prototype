RSpec.describe AccountManagerApplication, type: :unit do
  context "the application exists" do
    let!(:application) do
      FactoryBot.create(
        :oauth_application,
        name: AccountManagerApplication::NAME,
        redirect_uri: AccountManagerApplication::REDIRECT_URI,
        scopes: AccountManagerApplication::SCOPES,
      )
    end

    it "returns the application" do
      expect(described_class.fetch&.id).to eq(application.id)
    end
  end

  context "the application doesn't exist" do
    it "creates the application" do
      application = described_class.fetch
      expect(application).to_not be_nil
      expect(application.name).to eq(AccountManagerApplication::NAME)
      expect(application.redirect_uri).to eq(AccountManagerApplication::REDIRECT_URI)
      expect(application.scopes).to eq(AccountManagerApplication::SCOPES)
    end
  end
end
