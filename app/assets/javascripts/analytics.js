//= require govuk_publishing_components/analytics

var gaProperty = "UA-26179049-28"
var gaPropertyCrossDomain = "UA-145652997-1"
var linkedDomains = ['www.gov.uk']

$(document).ready(function() {
  if (typeof window.GOVUK.analyticsInit !== 'undefined') {
    window.GOVUK.analyticsInit(gaProperty, gaPropertyCrossDomain, linkedDomains)

    if (window.GOVUK.cookie('cookies_preferences_set') && window.GOVUK.cookie('cookies_policy')) {
      var currentConsentCookie = JSON.parse(window.GOVUK.cookie('cookies_policy'))
      if (currentConsentCookie.usage === true) {
        $('input[name=cookie_consent][value=yes]').prop('checked', true)
      } else {
        $('input[name=cookie_consent][value=no]').prop('checked', true)
      }
    }

    $('.js-cookie-consent .govuk-radios__input').on('click', function() {
      var response = $(this).val()

      if (response === 'yes') {
        window.GOVUK.approveAllCookieTypes()
        window.GOVUK.cookie('cookies_preferences_set', 'true', { days: 365 })
        window.GOVUK.analyticsInit(gaProperty, gaPropertyCrossDomain, linkedDomains)
      }

      else {
        window.GOVUK.deleteCookie('cookies_policy')
      }
    })
  }
})
