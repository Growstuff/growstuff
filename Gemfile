source 'https://rubygems.org'

ruby "2.1.2"

# gems for Rails 4 upgrade
gem 'rails4_upgrade'
gem 'actionpack-action_caching', '~>1.0.0'
gem 'actionpack-page_caching', '~>1.0.0'
gem 'actionpack-xml_parser', '~>1.0.0'
gem 'actionview-encoded_mail_to', '~>1.0.4'
gem 'activerecord-session_store', '~>0.0.1'
gem 'activeresource', '~>4.0.0.beta1'
gem 'protected_attributes', '~>1.0.1'
gem 'rails-observers', '~>0.1.1'
gem 'rails-perftest', '~>0.0.2'

gem 'bundler', '>=1.1.5'

gem 'rails', '4.1.7'
# gem 'rack', '~>1.4.5'
# gem 'json', '~>1.7.7'
gem 'haml'
gem 'leaflet-rails'
gem 'leaflet-markercluster-rails'
gem 'unicorn' # http server

gem 'pg'

gem 'figaro' # for handling config via ENV variables

gem 'cancan' # for checking member privileges

gem 'gibbon' # for Mailchimp newsletter subscriptions

gem 'csv_shaper' # CSV export

# vendored activemerchant for testing- needed for bogus paypal
# gateway monkeypatch
gem 'activemerchant', '1.33.0',
  :path => 'vendor/gems/activemerchant-1.33.0',
  :require => 'active_merchant'
gem 'active_utils', '1.0.5',
  :path => 'vendor/gems/active_utils-1.0.5'

group :production, :staging do
  gem 'newrelic_rpm'
  gem 'dalli'
  gem 'memcachier'
  gem 'rails_12factor' # supresses heroku plugin injection
end

# CSS preprocessor, used for app/assets/stylesheets/application.css
gem 'sass-rails',   '~> 4.0.4'
# CoffeeScript is a Python-like language that compiles to JavaScript
gem 'coffee-rails', '~> 4.1.0'

# less-rails depends on a JavaScript engine; we use therubyracer.
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# long term, we'll probably want node.js for performance, but this will do
# for now as it's easier for new people to install
gem "therubyracer", "~> 0.12", :platforms => :ruby
# libv8 is needed by therubyracer and is a bit finicky
gem 'libv8', '3.16.14.3'

# Another CSS preprocessor, used for Bootstrap overrides
gem "less", '~>2.5.0'
gem "less-rails", '~> 2.5.0'
# CSS framework
gem "less-rails-bootstrap", '~> 3.2.0'

gem 'uglifier', '~> 2.5.3' # JavaScript compressor

# gem 'compass-rails', '~> 1.0.3' # Yet Another CSS framework

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'js-routes'  # provides access to Rails routes in Javascript
gem 'flickraw'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# To use debugger
group :development do
  # A debugger and irb alternative. Pry doesn't play nice
  # with unicorn, so start a Webrick server when debugging
  # with Pry
  gem 'pry'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'letter_opener'
end

# Markdown formatting for updates etc
gem 'bluecloth'

# Pagination
gem 'will_paginate', '~> 3.0'

# user signup/login/etc
gem 'devise', '~> 3.2.0'

# nicely formatted URLs
gem 'friendly_id', '~> 5.0.4'

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
gem 'omniauth-flickr', '>= 0.0.15'

gem 'rake', '>= 10.0.0'

group :development, :test do
  gem 'haml-rails'                   # HTML templating language
  gem 'rspec-rails', '~> 3.1.0'      # unit testing framework
  gem 'database_cleaner', '~> 1.3.0'
  gem 'webrat'                       # provides HTML matchers for view tests
  gem 'factory_girl_rails', '~> 4.5.0' # for creating test data
  gem 'coveralls', require: false    # coverage analysis
  gem 'capybara'                     # integration tests
  gem 'capybara-email'               # integration tests for email
  gem 'poltergeist', '~> 1.5.1'      # for headless JS testing
  gem 'i18n-tasks'                   # adds tests for finding missing and unused translations
end
