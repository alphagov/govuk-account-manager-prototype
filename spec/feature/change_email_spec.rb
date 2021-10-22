RSpec.feature "Change Email" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { FactoryBot.create(:user) }

  it "displays the migration warning" do
    log_in
    go_to_change_email_page

    expect(page).to have_text("You cannot update this information at the moment")
  end

  def go_to_change_email_page
    visit account_manage_path
    within "#main-content" do
      click_on "Change Email"
    end
  end
end
