require "gds_api/test_helpers/account_api"

RSpec.describe UpdateUserInAccountApiJob do
  include GdsApi::TestHelpers::AccountApi

  let(:user) { FactoryBot.create(:user, :confirmed) }
  let(:application) { FactoryBot.create(:oauth_application) }
  let(:subject_identifier) { Doorkeeper::OpenidConnect.configuration.subject.call(user, application).to_s }

  around do |example|
    ClimateControl.modify(ACCOUNT_API_DOORKEEPER_UID: application.uid) do
      example.run
    end
  end

  it "calls account-api" do
    stub = stub_update_user_by_subject_identifier(
      subject_identifier: subject_identifier,
      email: user.email,
      email_verified: user.confirmed?,
    )

    described_class.perform_now user.id

    expect(stub).to have_been_made
  end
end
