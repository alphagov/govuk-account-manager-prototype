RSpec.describe "register" do
  include ActiveJob::TestHelper
  include Capybara::DSL

  let(:email) { "email@example.com" }
  let(:password) { "abcd1234" } # pragma: allowlist secret
  let(:password_confirmation) { password }

  it "creates a user" do
    enter_email_address
    enter_password_and_confirmation
    accept_terms

    expect(page).to have_text(I18n.t("post_registration.heading"))

    expect(User.last).to_not be_nil
    expect(User.last.email).to eq(email)
  end

  it "sends an email" do
    enter_email_address
    enter_password_and_confirmation
    accept_terms

    assert_enqueued_jobs 1, only: NotifyDeliveryJob
  end

  it "shows the terms & conditions" do
    enter_email_address
    enter_password_and_confirmation

    expect(page).to have_text(I18n.t("devise.registrations.new.needs_consent.heading"))
  end

  context "when the email is missing" do
    let(:email) { "" }

    it "shows an error" do
      enter_email_address

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.blank"))
    end
  end

  context "when the email is invalid" do
    let(:email) { "foo" }

    it "shows an error" do
      enter_email_address

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.email.blank"))
    end
  end

  context "when the password is missing" do
    let(:password) { "" }

    it "returns an error" do
      enter_email_address
      enter_password_and_confirmation

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.password.blank"))
    end
  end

  context "when the password confirmation is missing" do
    let(:password_confirmation) { "" }

    it "returns an error" do
      enter_email_address
      enter_password_and_confirmation

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.password_confirmation.confirmation"))
    end
  end

  context "when the password confirmation does not match" do
    let(:password_confirmation) { password + "-123" }

    it "returns an error" do
      enter_email_address
      enter_password_and_confirmation

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.password_confirmation.confirmation"))
    end
  end

  context "when the password is less than 8 characters" do
    let(:password) { "qwerty1" }

    it "returns an error" do
      enter_email_address
      enter_password_and_confirmation

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.password.too_short"))
    end
  end

  context "when the password does not contain a number" do
    let(:password) { "qwertyui" }

    it "returns an error" do
      enter_email_address
      enter_password_and_confirmation

      expect(page).to have_text(I18n.t("activerecord.errors.models.user.attributes.password.invalid"))
    end
  end

  def enter_email_address
    visit "/"
    fill_in "email", with: email
    click_on I18n.t("welcome.show.button.label")
  end

  def enter_password_and_confirmation
    fill_in "password", with: password
    fill_in "password_confirmation", with: password_confirmation
    click_on I18n.t("devise.registrations.new.needs_password.fields.submit.label")
  end

  def accept_terms
    click_on I18n.t("devise.registrations.new.needs_consent.fields.submit.label")
  end
end
