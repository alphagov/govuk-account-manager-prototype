# Use this file to set/override Jasmine configuration options
# You can remove it if you don't need it.
# This file is loaded *after* jasmine.yml is interpreted.
#
# Example: using a different boot file.
# Jasmine.configure do |config|
#    config.boot_dir = '/absolute/path/to/boot_dir'
#    config.boot_files = lambda { ['/absolute/path/to/boot_dir/file.js'] }
# end
#
# Example: prevent PhantomJS auto install, uses PhantomJS already on your path.
require "jasmine_selenium_runner/configure_jasmine"

class HeadlessChromeJasmineConfigurer < JasmineSeleniumRunner::ConfigureJasmine
  def selenium_options
    { options: GovukTest.headless_chrome_selenium_options }
  end
end

Jasmine.configure do |config|
  if ENV["TRAVIS"]
    config.prevent_phantom_js_auto_install = true
  end
end
