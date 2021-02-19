RSpec.feature "Authenticate with a new a webauthn key" do
  secnario do
    # We had some difficulty getting these to work. The JS will trigger a web browser API which will present the user with a modal box
    # that they can use to authenticate from this point on. However capybara does not appear to have access to that API, and we would need to
    # find a way of stubbing the input from a yubikey.
    # There are some testing methods that come with the library here: https://github.com/cedarcode/webauthn-ruby/blob/master/lib/webauthn/fake_client.rb
    # However our conclusion is, you cannot feature test registration / authententication
    # Instead we would need to use the webauthn-ruby libray stubs to write feature tests.
    # This means the majoirty of the JS code needs to be unit tested easily.
    # Though we note: https://www.selenium.dev/selenium/docs/api/rb/Selenium/WebDriver/DevTools/WebAuthn.html#add_virtual_authenticator-instance_method
  end
end
