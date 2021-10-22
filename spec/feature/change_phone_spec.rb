RSpec.feature "Change Phone" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { FactoryBot.create(:user) }

  it "displays the migration warning" do
    log_in
    go_to_change_number_page

    expect(page).to have_text("You cannot update this information at the moment")
  end

  def go_to_change_number_page
    visit account_manage_path
    within "#main-content" do
      click_on "Change Mobile number"
    end
  end
end
