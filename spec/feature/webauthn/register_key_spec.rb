RSpec.feature "Register a new a webauthn key" do
  scenario do
    given_i_am_signed_in_and_i_have_no_key_registered
    when_i_navigate_to_the_security_tab
    then_i_click_register_a_new_key
    then_i_see_the_register_key_form
    and_i_give_my_key_a_nickname
    and_i_submit_the_form
    # then_i_register_my_key_with_my_browser
    # then_i_see_my_new_key_registered_on_the_security_tab
  end

  def then_i_click_register_a_new_key
    click_on(I18n.t("account.security.webauthn.action.register_new"))
  end

  def then_i_see_the_register_key_form
    expect(page).to have_css(
      'h1',
      text: I18n.t("account.webauthn.registration.title"),
      visible: true
    )
  end

  def and_i_give_my_key_a_nickname
    fill_in 'credential_nickname', :with => 'nickname 1'
  end

  def and_i_submit_the_form
    click_on I18n.t("account.webauthn.registration.form.submit_button.label")
  end

  # def then_i_register_my_key_with_my_browser
    # We had some difficulty getting these to work. The JS will trigger a web browser API which will present the user with a modal box
    # that they can use to authenticate from this point on. However capybara does not appear to have access to that API, and we would need to
    # find a way of stubbing the input from a yubikey.
    # There are some testing methods that come with the library here: https://github.com/cedarcode/webauthn-ruby/blob/master/lib/webauthn/fake_client.rb
    # However our conclusion is, you cannot feature test registration / authententication
    # Instead we would need to use the webauthn-ruby libray stubs to write feature tests.
    # This means the majoirty of the JS code needs to be unit tested easily.
    # Though we note: https://www.selenium.dev/selenium/docs/api/rb/Selenium/WebDriver/DevTools/WebAuthn.html#add_virtual_authenticator-instance_method
  # end

  # def then_i_see_my_new_key_registered_on_the_security_tab
  #   then_i_see_registered_key("nickname 1")
  # end
end
