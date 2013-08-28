source 'https://rubygems.org'

gem 'bundler', '>=1.1.5'

gem 'rails', '3.2.13'
gem 'rack', '~>1.4.5'
gem 'json', '~>1.7.7'
gem 'haml'
gem 'leaflet-rails'
gem 'unicorn' # http server

gem 'cancan' # for checking member privileges

# vendored activemerchant for testing- needed for bogus paypal
# gateway monkeypatch
gem 'activemerchant', '1.33.0',
  :path => 'vendor/gems/activemerchant-1.33.0',
  :require => 'active_merchant'
gem 'active_utils', '1.0.5',
  :path => 'vendor/gems/active_utils-1.0.5'

group :production, :staging do
  gem 'pg'
  gem 'newrelic_rpm'
  gem 'dalli'
  gem 'memcachier'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  # CSS preprocessor, used for app/assets/stylesheets/application.css
  gem 'sass-rails',   '~> 3.2.3'
  # CoffeeScript is a Python-like language that compiles to JavaScript
  gem 'coffee-rails', '~> 3.2.1'

  # less-rails depends on a JavaScript engine; we use therubyracer.
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # long term, we'll probably want node.js for performance, but this will do
  # for now as it's easier for new people to install
  gem 'therubyracer', '~> 0.10.2', :platforms => :ruby
  # Another CSS preprocessor, used for Bootstrap overrides
  gem "less-rails"
  # CSS framework
  gem "twitter-bootstrap-rails",
    :git => 'https://github.com/seyhunak/twitter-bootstrap-rails.git',
    :ref => '2c7c52'

  gem 'uglifier', '>= 1.0.3' # JavaScript compressor

  gem 'compass-rails', '~> 1.0.3' # Yet Another CSS framework
end

gem 'jquery-rails'
gem 'flickraw'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# To use debugger
group :development do
  # Installation of the debugger gem fails on Travis CI,
  # so we don't use it in the test environment
  gem 'debugger'
end

# Markdown formatting for updates etc
gem 'bluecloth'

# Pagination
gem 'will_paginate', '~> 3.0'

# user signup/login/etc
gem 'devise'

# nicely formatted URLs
gem 'friendly_id'

# gravatars
gem 'gravatar-ultimate'

# For geolocation
gem 'geocoder',
  :git => 'https://github.com/alexreisner/geocoder.git',
  :ref => '104d46'

# For easy calendar selection
gem 'bootstrap-datepicker-rails'

# For connecting to other services (eg Twitter)
gem 'omniauth'
gem 'omniauth-twitter'
gem 'omniauth-flickr'

gem 'rake', '>= 10.0.0'

group :development, :test do
  gem 'sqlite3'                      # database engine
end

group :development, :test, :travis do
  gem 'haml-rails'                   # HTML templating language
  gem 'rspec-rails', '~> 2.12.1'     # unit testing framework
  gem 'webrat'                       # provides HTML matchers for view tests
  gem 'factory_girl_rails', '~> 4.0' # for creating test data
  gem 'coveralls', require: false    # coverage analysis
end
