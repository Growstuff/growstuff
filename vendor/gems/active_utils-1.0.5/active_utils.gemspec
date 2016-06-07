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

  # Originally the file lists were generated from git, but we hard-code them so
  # we don't need to install git in the container.
  # s.files         = `git ls-files`.split("\n")
  # s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  # s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files         = [".gitignore", "Gemfile", "MIT-LICENSE", "README.md",
                     "Rakefile", "active_utils.gemspec", "lib/active_utils.rb",
                     "lib/active_utils/common/connection.rb",
                     "lib/active_utils/common/country.rb",
                     "lib/active_utils/common/error.rb",
                     "lib/active_utils/common/network_connection_retries.rb",
                     "lib/active_utils/common/post_data.rb",
                     "lib/active_utils/common/posts_data.rb",
                     "lib/active_utils/common/requires_parameters.rb",
                     "lib/active_utils/common/utils.rb",
                     "lib/active_utils/common/validateable.rb",
                     "lib/active_utils/version.rb", "lib/certs/cacert.pem",
                     "test/test_helper.rb", "test/unit/connection_test.rb",
                     "test/unit/country_code_test.rb",
                     "test/unit/country_test.rb",
                     "test/unit/network_connection_retries_test.rb",
                     "test/unit/post_data_test.rb",
                     "test/unit/posts_data_test.rb", "test/unit/utils_test.rb",
                     "test/unit/validateable_test.rb"]
  s.test_files    = ["test/test_helper.rb", "test/unit/connection_test.rb",
                     "test/unit/country_code_test.rb",
                     "test/unit/country_test.rb",
                     "test/unit/network_connection_retries_test.rb",
                     "test/unit/post_data_test.rb",
                     "test/unit/posts_data_test.rb", "test/unit/utils_test.rb",
                     "test/unit/validateable_test.rb"]
  s.executables   = []
  s.require_paths = ["lib"]
end
