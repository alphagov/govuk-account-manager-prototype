describe('Form tracker', function () {
  'use strict'

  var form

  beforeEach(function () {
    if (typeof window.ga === 'undefined') {
      window.ga = function () {}
    }
    spyOn(window, 'ga')

    form = $('<form onsubmit="event.preventDefault()"/>').attr('data-track-category', 'dummy-category')
    form.appendTo('body')
  })

  afterEach(function () {
    form.remove()
  })

  it('sends chosen options to Google Analytics when submitting the form', function () {
    var contents =
      '<label for="test1">Test 1</label>' +
      '<input type="checkbox" checked data-track-action="test1" id="test1"/>' +
      '<label for="test2">Test 2</label>' +
      '<input type="checkbox" checked data-track-action="test2" id="test2"/>' +
      '<button type="submit">submit</button>'
    form[0].innerHTML = contents
    new GOVUK.Modules.TrackForm().start(form)

    // need to submit the form like this otherwise jquery's submit overrides the JS version
    var button = form[0].querySelector('button')
    button.click()

    expect(window.ga).toHaveBeenCalledWith('send', { hitType: 'event', eventCategory: 'dummy-category', eventAction: 'test1', eventLabel: 'Test 1' })
    expect(window.ga).toHaveBeenCalledWith('send', { hitType: 'event', eventCategory: 'dummy-category', eventAction: 'test2', eventLabel: 'Test 2' })
  })

  it('sends chosen options to Google Analytics when submitting the form if the form is invalid', function () {
    var contents =
      '<label for="test1">Test 1</label>' +
      '<input type="checkbox" checked data-track-action="test1" id="test1"/>' +
      '<input type="checkbox" checked data-track-action="test2" id="test2"/>' +
      '<button type="submit">submit</button>'
    form[0].innerHTML = contents
    new GOVUK.Modules.TrackForm().start(form)

    // need to submit the form like this otherwise jquery's submit overrides the JS version
    var button = form[0].querySelector('button')
    button.click()

    expect(window.ga).toHaveBeenCalledWith('send', { hitType: 'event', eventCategory: 'dummy-category', eventAction: 'test1', eventLabel: 'Test 1' })
    expect(window.ga).toHaveBeenCalledWith('send', { hitType: 'event', eventCategory: 'dummy-category', eventAction: 'test2', eventLabel: 'No label found' })
  })

  it('does not send anything if the form does not contain the right things', function () {
    var contents = '<button type="submit">submit</button>'
    form[0].innerHTML = contents
    new GOVUK.Modules.TrackForm().start(form)

    var button = form[0].querySelector('button')
    button.click()

    expect(window.ga).not.toHaveBeenCalled()
  })
})
