# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_utils/version"

Gem::Specification.new do |s|
  s.name        = "active_utils"
  s.version     = ActiveUtils::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Shopify"]
  s.email       = ["developers@jadedpixel.com"]
  s.homepage    = "http://github.com/shopify/active_utils"
  s.summary     = %q{Common utils used by active_merchant, active_fulfillment, and active_shipping}

  s.rubyforge_project = "active_utils"

  s.add_dependency('activesupport', '>= 2.3.11')
  s.add_dependency('i18n')

  s.add_development_dependency('rake')
  s.add_development_dependency('mocha')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
