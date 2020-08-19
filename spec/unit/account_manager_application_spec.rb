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

    let!(:user) do
      FactoryBot.create(
        :user,
        email: "user@domain.tld",
        password: "breadbread1",
        password_confirmation: "breadbread1",
      )
    end

    it "returns the application" do
      expect(described_class.application&.id).to eq(application.id)
    end

    context "the token exists" do
      let!(:token) do
        Doorkeeper::AccessToken.create!(
          application_id: application.id,
          resource_owner_id: user.id,
          scopes: AccountManagerApplication::SCOPES,
        )
      end

      it "returns the token" do
        expect(described_class.user_token(token.resource_owner_id)&.id).to eq(token.id)
      end
    end

    context "the token doesn't exist" do
      it "creates the token" do
        token = described_class.user_token(user.id)
        expect(token).to_not be_nil
        expect(token.application_id).to eq(described_class.application.id)
        expect(token.resource_owner_id).to eq(user.id)
        expect(token.scopes).to eq(AccountManagerApplication::SCOPES)
      end
    end
  end

  context "the application doesn't exist" do
    it "creates the application" do
      application = described_class.application
      expect(application).to_not be_nil
      expect(application.name).to eq(AccountManagerApplication::NAME)
      expect(application.redirect_uri).to eq(AccountManagerApplication::REDIRECT_URI)
      expect(application.scopes).to eq(AccountManagerApplication::SCOPES)
    end
  end
end
