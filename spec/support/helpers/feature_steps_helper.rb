module FeatureStepsHelper
  def given_i_am_signed_in_and_i_have_no_key_registered
    sign_in_as(FactoryBot.create(:user))
  end

  def given_i_am_signed_in_and_i_have_a_key_registered
    sign_in_as(user_with_credentials)
  end

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "email", with: user.email
    fill_in "password", with: user.password
    click_on I18n.t("devise.sessions.new.fields.submit.label")

    fill_in "phone_code", with: user.reload.phone_code
    click_on I18n.t("mfa.phone.code.fields.submit.label")
  end

  def user_with_credentials
    @user_with_credentials ||= FactoryBot.create(:user, :with_webauthn_credentials)
  end

  def when_i_navigate_to_the_security_tab
    click_on(I18n.t("navigation.menu_bar.security.link_text"))
  end

  def then_i_see_registered_key(key_nickname)
    within ".security-key-list" do
      expect(page).to have_content(key_nickname)
    end
  end
end

RSpec.configuration.send :include, FeatureStepsHelper
