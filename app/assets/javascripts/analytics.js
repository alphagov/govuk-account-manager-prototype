//= require govuk_publishing_components/analytics

var linkedDomains = ['www.gov.uk']

$(document).ready(function() {
  if (typeof window.GOVUK.analyticsInit !== 'undefined') {
    window.GOVUK.analyticsInit(linkedDomains)

    $('.js-cookie-consent .govuk-radios__input').on('click', function() {
      var response = $(this).val()

      if (response === 'yes') {
        window.GOVUK.approveAllCookieTypes()
        window.GOVUK.cookie('cookies_preferences_set', 'true', { days: 365 })
        window.GOVUK.analyticsInit(linkedDomains)
      }

      else {
        window.GOVUK.deleteCookie('cookies_policy')
      }
    })
  }
})
