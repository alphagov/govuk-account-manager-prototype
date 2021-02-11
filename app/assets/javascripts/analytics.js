//= require govuk_publishing_components/analytics

window.GOVUK.analyticsVars = window.GOVUK.analyticsVars || {}
window.GOVUK.analyticsVars.gaProperty = "UA-26179049-28"
window.GOVUK.analyticsVars.gaPropertyCrossDomain = "UA-145652997-1"
window.GOVUK.analyticsVars.linkedDomains = ['www.gov.uk']

if (typeof window.GOVUK.analyticsInit !== 'undefined') {
  window.GOVUK.analyticsInit()

  var cookieConsentRadio = document.querySelectorAll('input[name=cookie_consent]')
  if (window.GOVUK.cookie('cookies_preferences_set') && window.GOVUK.cookie('cookies_policy') && cookieConsentRadio.length) {
    var currentConsentCookie = JSON.parse(window.GOVUK.cookie('cookies_policy'))
    if (currentConsentCookie.usage === true) {
      document.querySelector('input[name=cookie_consent][value=yes]').checked = true
    } else {
      document.querySelector('input[name=cookie_consent][value=no]').checked = true
    }
  }
}
