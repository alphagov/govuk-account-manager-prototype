RSpec.feature "Confirm email prompt" do
  context "For a newly created account" do
    let(:user) { FactoryBot.create(:user) }

    scenario "Banner is present for user with unconfirmed email address" do
      given_i_have_logged_in
      when_i_navigate_to_home
      then_i_see_the_confirmation_reminder_banner
      and_i_see_a_confirmation_intro_for_setting_up_an_account
      when_i_navigate_to_manage
      then_i_see_the_confirmation_reminder_banner
      and_i_see_a_confirmation_intro_for_setting_up_an_account
      when_i_navigate_to_security
      then_i_see_the_confirmation_reminder_banner
      and_i_see_a_confirmation_intro_for_setting_up_an_account
    end

    scenario "Resend form is prefilled on new user signup" do
      given_i_have_logged_in
      when_i_navigate_to_home
      then_i_see_the_confirmation_reminder_banner
      when_i_click_the_link_on_the_confirmation_banner
      then_i_see_the_new_confirmaton_page_header
      and_my_email_address_should_be_prefilled_in_the_form
    end

    scenario "Banner is not present once user has confirmed email address" do
      given_i_have_logged_in
      when_i_navigate_to_home
      then_i_see_the_confirmation_reminder_banner
      when_i_confirm_my_email_with_a_confirmation_link
      when_i_navigate_to_home
      then_i_do_not_see_the_confirmation_reminder_banner
    end
  end

  context "For an existing user requesting to change their email address" do
    let(:user) { FactoryBot.create(:user, :confirmed, :email_change_requested) }

    scenario "Resend form is prefilled for changed email address" do
      given_i_have_logged_in
      when_i_navigate_to_home
      then_i_see_the_confirmation_reminder_banner
      and_i_see_a_confirmation_intro_for_updating_an_account
      when_i_click_the_link_on_the_confirmation_banner
      then_i_see_the_new_confirmaton_page_header
      and_my_unconfirmed_email_address_should_be_prefilled
    end

    scenario "Banner is not present once user has confirmed email address" do
      given_i_have_logged_in
      when_i_navigate_to_home
      then_i_see_the_confirmation_reminder_banner
      and_i_see_a_confirmation_intro_for_updating_an_account
      when_i_confirm_my_email_with_a_confirmation_link
      when_i_navigate_to_home
      then_i_do_not_see_the_confirmation_reminder_banner
    end
  end

  def given_i_have_logged_in
    visit new_user_session_path
    fill_in "email", with: user.email
    fill_in "password", with: "abcd1234"
    click_on I18n.t("devise.sessions.new.fields.submit.label")
  end

  def when_i_navigate_to_home
    visit user_root_path
  end

  def when_i_navigate_to_manage
    visit account_manage_path
  end

  def when_i_navigate_to_security
    visit account_security_path
  end

  def then_i_see_the_confirmation_reminder_banner
    expect(page).to have_content(I18n.t("confirm.link_text"))
  end

  def when_i_click_the_link_on_the_confirmation_banner
    click_link(I18n.t("confirm.link_text"))
  end

  def then_i_see_the_new_confirmaton_page_header
    expect(page).to have_content(I18n.t("devise.confirmations.resend.heading"))
  end

  def and_my_email_address_should_be_prefilled_in_the_form
    expect(page).to have_field(I18n.t("devise.confirmations.resend.label"), with: user.email)
  end

  def and_my_unconfirmed_email_address_should_be_prefilled
    expect(page).to have_field(I18n.t("devise.confirmations.resend.label"), with: user.unconfirmed_email)
  end

  def when_i_confirm_my_email_with_a_confirmation_link
    visit user_confirmation_path(confirmation_token: user.confirmation_token)
  end

  def and_i_see_a_confirmation_intro_for_setting_up_an_account
    expect(page).to have_content(Rails::Html::FullSanitizer.new.sanitize(I18n.t("confirm.intro.set_up")))
  end

  def and_i_see_a_confirmation_intro_for_updating_an_account
    expect(page).to have_content(Rails::Html::FullSanitizer.new.sanitize(I18n.t("confirm.intro.update")))
  end

  def then_i_do_not_see_the_confirmation_reminder_banner
    expect(page).not_to have_content(I18n.t("confirm.link_text"))
  end
end
