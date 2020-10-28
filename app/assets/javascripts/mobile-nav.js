// This is an override of the existing mobile menu functionality to display an experimental variant of the mobile navigation for the account manager view
// THIS FUNCTIONALITY IS STILL EXPERIMENTAL
// Please consider removing this module or moving it into the components gem once this mobile nav pattern has been tested with users

window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function () {
  'use strict'

  var menuButton = document.querySelector(".govuk-js-header-toggle")
  var mobileMenu = document.querySelector(".js-mobile-menu")
  var menuExpanded = false
  
  if (menuButton && mobileMenu) {
    menuButton.setAttribute("aria-controls", "mobile-navigation")
    menuButton.setAttribute("aria-expanded", menuExpanded)

    menuButton.addEventListener("click", function(e) {
      menuExpanded = !menuExpanded

      mobileMenu.classList.toggle("accounts-mobile-menu--active")
      mobileMenu.setAttribute("aria-hidden", !menuExpanded)

      menuButton.classList.toggle("govuk-header__menu-button--open")
      menuButton.setAttribute("aria-expanded", menuExpanded)
    })
  }
})(window, window.GOVUK)
