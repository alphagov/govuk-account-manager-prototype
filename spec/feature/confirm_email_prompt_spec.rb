RSpec.feature "Confirm email prompt" do
  context "For an existing user requesting to change their email address" do
    let(:user) { FactoryBot.create(:user, :confirmed, :email_change_requested) }

    scenario "They see the migration warning banner" do
      given_i_have_logged_in
      when_i_navigate_to_manage
      then_i_see_the_migration_warning_banner
    end
  end

  def given_i_have_logged_in
    visit new_user_session_path
    fill_in "email", with: user.email
    fill_in "password", with: "abcd1234"
    click_on I18n.t("devise.sessions.new.fields.submit.label")
    fill_in "phone_code", with: user.reload.phone_code
    click_on I18n.t("mfa.phone.code.fields.submit.label")
  end

  def when_i_navigate_to_manage
    visit account_manage_path
  end

  def then_i_see_the_migration_warning_banner
    expect(page).to have_text("You cannot update your account details at the moment")
  end
end
