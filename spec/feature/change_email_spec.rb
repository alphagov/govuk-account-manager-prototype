RSpec.feature "Change Email" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { FactoryBot.create(:user) }

  let(:new_email) { "test@testing.com" }

  context "when the change email form is submitted with correct details" do
    it "displays the confirmation instructions page" do
      log_in
      go_to_change_email_page
      enter_new_email
      enter_password

      expect(page).to have_text(I18n.t("confirmation_sent.heading.confirm_change"))
    end

    it "notifies the user about the update" do
      log_in
      go_to_change_email_page
      enter_new_email
      enter_password

      assert_enqueued_jobs 2, only: NotifyDeliveryJob
    end
  end

  context "when the user enters the same email" do
    it "returns an error" do
      log_in
      go_to_change_email_page
      enter_same_email
      enter_password

      expect(page).to have_text(I18n.t("devise.failure.same_email"))
    end

    it "displays the current email" do
      log_in
      go_to_change_email_page
      enter_same_email
      enter_password

      expect(page).to have_text(I18n.t("devise.registrations.edit.fields.email.inset_text", email: user.email))
    end
  end

  context "when the email is invalid" do
    it "returns an error" do
      log_in
      go_to_change_email_page
      enter_invalid_email
      enter_password

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.invalid"))
    end

    it "displays the current email" do
      log_in
      go_to_change_email_page
      enter_same_email
      enter_password

      expect(page).to have_text(I18n.t("devise.registrations.edit.fields.email.inset_text", email: user.email))
    end
  end

  context "when the email field is empty" do
    it "returns an error" do
      log_in
      go_to_change_email_page
      enter_empty_email
      enter_password

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.blank"))
    end

    it "displays the current email" do
      log_in
      go_to_change_email_page
      enter_same_email
      enter_password

      expect(page).to have_text(I18n.t("devise.registrations.edit.fields.email.inset_text", email: user.email))
    end
  end

  context "when the password is incorrect" do
    it "returns an error" do
      log_in
      go_to_change_email_page
      enter_new_email
      enter_incorrect_password

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.current_password.invalid"))
    end

    it "displays the current email" do
      log_in
      go_to_change_email_page
      enter_new_email
      enter_incorrect_password

      expect(page).to have_text(I18n.t("devise.registrations.edit.fields.email.inset_text", email: user.email))
    end
  end

  def go_to_change_email_page
    visit account_manage_path
    within "#main-content" do
      click_on "Change Email"
    end
  end

  def enter_new_email
    fill_in "email", with: new_email
  end

  def enter_same_email
    fill_in "email", with: user.email
  end

  def enter_invalid_email
    fill_in "email", with: "BLAH"
  end

  def enter_empty_email
    fill_in "email", with: ""
  end

  def enter_password
    fill_in "current__confirmation", with: user.password
    click_on I18n.t("devise.registrations.edit.fields.submit.label")
  end

  def enter_incorrect_password
    fill_in "current__confirmation", with: "asdf#{user.password}"
    click_on I18n.t("devise.registrations.edit.fields.submit.label")
  end
end
