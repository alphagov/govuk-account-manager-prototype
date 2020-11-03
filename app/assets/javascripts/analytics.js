//= require govuk_publishing_components/analytics

window.GOVUK.analyticsVars = window.GOVUK.analyticsVars || {}
window.GOVUK.analyticsVars.gaProperty = "UA-26179049-28"
window.GOVUK.analyticsVars.gaPropertyCrossDomain = "UA-145652997-1"
window.GOVUK.analyticsVars.linkedDomains = ['www.gov.uk']

if (typeof window.GOVUK.analyticsInit !== 'undefined') {
  window.GOVUK.analyticsInit()

  if (window.GOVUK.cookie('cookies_preferences_set') && window.GOVUK.cookie('cookies_policy')) {
    var currentConsentCookie = JSON.parse(window.GOVUK.cookie('cookies_policy'))
    if (currentConsentCookie.usage === true) {
      $('input[name=cookie_consent][value=yes]').prop('checked', true)
    } else {
      $('input[name=cookie_consent][value=no]').prop('checked', true)
    }
  }
}
