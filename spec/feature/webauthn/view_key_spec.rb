RSpec.feature "View WebAuthn security keys" do
  scenario do
    given_i_am_signed_in_and_i_have_no_key_registered
    when_i_navigate_to_the_security_tab
    then_i_see_no_keys_registered
  end

  scenario do
    given_i_am_signed_in_and_i_have_a_key_registered
    when_i_navigate_to_the_security_tab
    then_i_see_my_registered_keys
  end

  def then_i_see_no_keys_registered
    expect(page).to have_content(I18n.t("account.security.webauthn.none.text"))
  end

  def then_i_see_my_registered_keys
    credential_nicknames = user_with_credentials.webauthn_credentials.map(&:nickname)
    credential_nickname.each { |key_nickname| then_i_see_registered_key(key_nickname) }
  end
end
