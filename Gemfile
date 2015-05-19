source 'https://rubygems.org'

ruby '2.1.5'

gem 'rails', '4.1.9'

gem 'bundler', '>=1.1.5'

gem 'sass-rails',   '~> 4.0.4'
gem 'coffee-rails', '~> 4.1.0'
gem 'haml'

# Another CSS preprocessor, used for Bootstrap overrides
gem 'less', '~>2.5.0'
gem 'less-rails', '~> 2.5.0'
# CSS framework
gem 'less-rails-bootstrap', '~> 3.2.0'

gem 'uglifier', '~> 2.5.3'         # JavaScript compressor

gem 'jquery-rails'
gem 'jquery-ui-rails', '~> 5.0.2'
gem 'js-routes'  # provides access to Rails routes in Javascript
gem 'flickraw'

gem 'leaflet-rails'
gem 'leaflet-markercluster-rails'
gem 'unicorn'                      # http server
gem 'pg'
gem 'figaro'                       # for handling config via ENV variables
gem 'cancancan', '~> 1.9'          # for checking member privileges
gem 'gibbon'                       # for Mailchimp newsletter subscriptions
gem 'csv_shaper'                   # CSV export
gem 'ruby-units'                   # for unit conversion

gem 'comfortable_mexican_sofa', '~> 1.12.0' # content management system

# vendored activemerchant for testing- needed for bogus paypal
# gateway monkeypatch
gem 'activemerchant', '1.33.0',
  :path    => 'vendor/gems/activemerchant-1.33.0',
  :require => 'active_merchant'
gem 'active_utils', '1.0.5',
  :path    => 'vendor/gems/active_utils-1.0.5'

# less-rails depends on a JavaScript engine; we use therubyracer.
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# long term, we'll probably want node.js for performance, but this will do
# for now as it's easier for new people to install
gem 'therubyracer', '~> 0.12', :platforms => :ruby
# libv8 is needed by therubyracer and is a bit finicky
gem 'libv8', '3.16.14.7'

# Markdown formatting for updates etc
gem 'bluecloth'

# Pagination
gem 'will_paginate', '~> 3.0'

# user signup/login/etc
gem 'devise', '~> 3.4.1'

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

# client for Elasticsearch. Elasticsearch is a flexible
# and powerful, distributed, real-time search and analytics engine. 
# An example of the use in the project is fuzzy crop search.
gem "elasticsearch-model"
gem "elasticsearch-rails"

gem 'rake', '>= 10.0.0'

group :production, :staging do
  gem 'newrelic_rpm'
  gem 'dalli'
  gem 'memcachier'
  gem 'rails_12factor' # supresses heroku plugin injection
  gem 'bonsai-elasticsearch-rails'  # Integration with Bonsa-Elasticsearch on heroku
end

group :development do
  # A debugger and irb alternative. Pry doesn't play nice
  # with unicorn, so start a Webrick server when debugging
  # with Pry
  gem 'pry'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'letter_opener'
  gem 'quiet_assets'
end

group :development, :test do
  gem 'haml-rails'                      # HTML templating language
  gem 'rspec-rails', '~> 3.1.0'         # unit testing framework
  gem 'rspec-activemodel-mocks'
  gem 'byebug'                          # debugging
  gem 'database_cleaner', '~> 1.3.0'
  gem 'webrat'                          # provides HTML matchers for view tests
  gem 'factory_girl_rails', '~> 4.5.0'  # for creating test data
  gem 'coveralls', require: false       # coverage analysis
  gem 'capybara'                        # integration tests
  gem 'capybara-email'                  # integration tests for email
  gem 'poltergeist', '~> 1.6'           # for headless JS testing
  gem 'i18n-tasks'                      # adds tests for finding missing and unused translations
end

group :travis do
  gem 'heroku-api'
end
