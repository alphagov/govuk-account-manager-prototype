/* eslint-env jquery */
/* global ga:readonly */

window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (global, GOVUK) {
  'use strict'

  var $ = global.jQuery

  GOVUK.Modules.TrackForm = function () {
    this.start = function (element) {
      track(element)
    }

    function track (element) {
      element.on('submit', function (event) {
        var $checkedOption, questionValue
        var $submittedForm = $(event.target)
        var $checkedOptions = $submittedForm.find('input:checked')
        var trackCategory = $submittedForm.data('track-category')

        if ($checkedOptions.length) {
          $checkedOptions.each(function (index) {
            $checkedOption = $(this)
            var trackAction = $checkedOption.data('track-action')
            var checkedOptionId = $checkedOption.attr('id')
            var checkedOptionLabel = $submittedForm.find('label[for="' + checkedOptionId + '"]').text().trim()
            questionValue = checkedOptionLabel.length ? checkedOptionLabel : $checkedOption.val()

            if (typeof ga === 'function') {
              ga('send', {
                hitType: 'event',
                eventCategory: trackCategory,
                eventAction: trackAction,
                eventLabel: questionValue
              })
            }
          })
        }
      })
    }
  }
})(window, window.GOVUK)
