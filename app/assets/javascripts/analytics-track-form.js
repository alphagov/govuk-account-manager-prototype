/* eslint-env jquery */
/* global ga:readonly */

window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (global, GOVUK) {
  'use strict'

  GOVUK.Modules.TrackForm = function () {
    this.start = function (element) {
      element[0].addEventListener('submit', function(event) {
        var $checkedOption, questionValue
        var $submittedForm = event.target
        var $checkedOptions = $submittedForm.querySelectorAll('input:checked')
        var trackCategory = $submittedForm.getAttribute('data-track-category')

        if ($checkedOptions.length) {
          for (var i = 0; i < $checkedOptions.length; i++) {
            $checkedOption = $checkedOptions[i]
            var trackAction = $checkedOption.getAttribute('data-track-action')
            var checkedOptionId = $checkedOption.getAttribute('id')
            var checkedOptionLabel = $submittedForm.querySelector('label[for="' + checkedOptionId + '"]')
            if (checkedOptionLabel) {
              checkedOptionLabel = checkedOptionLabel.textContent.trim()
            } else {
             checkedOptionLabel =  "No label found"
            }
            questionValue = checkedOptionLabel.length ? checkedOptionLabel : $checkedOption.value

            if (typeof ga === 'function') {
              ga('send', {
                hitType: 'event',
                eventCategory: trackCategory,
                eventAction: trackAction,
                eventLabel: questionValue
              })
            }
          }
        }
      })
    }
  }
})(window, window.GOVUK)
