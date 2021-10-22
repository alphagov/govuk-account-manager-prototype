RSpec.feature "Registration" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  it "shows the warning message" do
    visit_registration_page

    expect(page).to have_text(I18n.t("devise.registrations.migration.sub_title"))
  end

  it "redirects other pages to the registration page" do
    visit_phone_code_page

    expect(page.current_path).to eq "/new-account"
  end

  def visit_registration_page
    visit new_user_registration_start_path
  end

  def visit_phone_code_page
    visit "/new-account/phone/code"
  end
end
