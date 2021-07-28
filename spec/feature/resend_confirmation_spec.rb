RSpec.feature "Resending confirmation email" do
  include ActiveJob::TestHelper

  let!(:user) { FactoryBot.create(:user) }

  before { clear_enqueued_jobs }

  it "sends the user a new confirmation email" do
    enter_email_address

    assert_enqueued_jobs 1, only: NotifyDeliveryJob
    expect(page).to have_text(I18n.t("confirmation_sent.help.heading"))
    expect(page).to have_text(user.email)
  end

  def enter_email_address(email: user.email)
    visit new_user_confirmation_path
    fill_in "email", with: email
    click_on I18n.t("devise.confirmations.resend.button")
  end
end
