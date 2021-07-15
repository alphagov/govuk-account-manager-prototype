RSpec.describe User do
  let(:attribute_service_url) { "https://attribute-service" }

  let(:user) { FactoryBot.create(:user) }

  let(:bearer_token) { AccountManagerApplication.user_token(user.id).token }

  around do |example|
    ClimateControl.modify(ATTRIBUTE_SERVICE_URL: attribute_service_url) do
      example.run
    end
  end

  context "#destroy!" do
    it "calls the attribute service to delete the attributes" do
      attribute_service_stub = stub_attribute_service_delete_all
      user.destroy!
      expect(attribute_service_stub).to have_been_made
    end

    def stub_attribute_service_delete_all
      stub_request(:delete, "#{attribute_service_url}/v1/attributes/all")
        .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
        .to_return(status: 200)
    end
  end

  context "#phone" do
    it "is formatted in E.164 format on save" do
      user.update!(phone: "07958 123 456")

      expect(user.phone).to eq("+447958123456")
    end
  end
end
