RSpec.describe ApplicationKey do
  let!(:application) do
    FactoryBot.create(
      :oauth_application,
      name: "name",
      redirect_uri: "http://localhost",
      scopes: %i[test_scope_write],
    )
  end

  it "round-trips the PEM" do
    private_key = OpenSSL::PKey::EC.new "prime256v1"
    private_key.generate_key
    public_key = OpenSSL::PKey::EC.new private_key

    key = ApplicationKey.create!(
      application_uid: application.uid,
      key_id: SecureRandom.uuid,
      pem: public_key.to_pem,
    )

    expect(key.to_key.to_pem).to eq(public_key.to_pem)
  end
end
