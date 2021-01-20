RSpec.describe RegistrationState do
  let(:registration_state) { FactoryBot.create(:registration_state, touched_at: Time.zone.now, state: :phone) }

  context "#phone" do
    it "is formatted in E.164 format on save" do
      registration_state.update!(phone: "07958 123 456")

      expect(registration_state.phone).to eq("+447958123456")
    end
  end
end
