# frozen_string_literal: true
source 'https://rubygems.org'

ruby '2.3.3'

gem 'rails', '~> 4.2.7'

gem 'bundler', '>=1.1.5'

gem 'coffee-rails', '~> 4.1.0'
gem 'haml'
gem 'sass-rails', '~> 5.0.4'

# CSS framework
gem 'bootstrap-sass', '~> 3.3.6'
gem 'font-awesome-sass'

gem 'uglifier', '~> 2.7.2' # JavaScript compressor

gem 'flickraw'
gem 'jquery-rails'
gem 'jquery-ui-rails', '~> 5.0.2'
gem 'js-routes' # provides access to Rails routes in Javascript

gem 'cancancan', '~> 1.9'          # for checking member privileges
gem 'csv_shaper'                   # CSV export
gem 'figaro'                       # for handling config via ENV variables
gem 'gibbon', '~>1.2.0'            # for Mailchimp newsletter subscriptions
gem 'leaflet-markercluster-rails'
gem 'leaflet-rails'
gem 'pg'
gem 'ruby-units'                   # for unit conversion
gem 'unicorn'                      # http server

gem 'comfortable_mexican_sofa', '~> 1.12.0' # content management system

gem 'bootstrap-kaminari-views'     # bootstrap views for kaminari
gem 'kaminari'                     # pagination

gem 'active_utils'
gem 'activemerchant'
gem 'sidekiq'

# Markdown formatting for updates etc
gem 'bluecloth'

# Pagination
gem 'will_paginate', '~> 3.0'

# user signup/login/etc
gem 'devise', '>= 4.0.0'

# nicely formatted URLs
gem 'friendly_id', '~> 5.0.4'

# gravatars
gem 'gravatar-ultimate'

# For geolocation
gem 'geocoder'

# For easy calendar selection
gem 'bootstrap-datepicker-rails'

# For connecting to other services (eg Twitter)
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-flickr', '>= 0.0.15'
gem 'omniauth-twitter'

# For charting data
gem 'd3-rails'

# client for Elasticsearch. Elasticsearch is a flexible
# and powerful, distributed, real-time search and analytics engine.
# An example of the use in the project is fuzzy crop search.

# Project does not use semver, so we want to be in sync with the version of
# elasticsearch we use
# See https://github.com/elastic/elasticsearch-ruby#compatibility
gem "elasticsearch-api", "~> 2.0.0"
gem "elasticsearch-model"
gem "hashie", "~> 3.4.4" # Required by elasticsearch-model, but needs to be pinned due to http://stackoverflow.com/questions/42170666/bundlergemrequireerror-there-was-an-error-while-trying-to-load-the-gem-omnia
gem "elasticsearch-rails"

gem 'rake', '>= 10.0.0'

# # CMS
# gem 'comfortable_mexican_sofa', '~> 1.12.0'

group :production, :staging do
  gem 'bonsai-elasticsearch-rails' # Integration with Bonsa-Elasticsearch on heroku
  gem 'dalli'
  gem 'memcachier'
  gem 'newrelic_rpm'
  gem 'rails_12factor' # supresses heroku plugin injection
  gem 'sparkpost_rails'
end

group :development do
  # A debugger and irb alternative. Pry doesn't play nice
  # with unicorn, so start a Webrick server when debugging
  # with Pry
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'guard'
  gem 'guard-rspec'
  gem 'letter_opener'
  gem 'pry'
  gem 'quiet_assets'
end

group :development, :test do
  gem "active_merchant-paypal-bogus-gateway"
  gem 'byebug'                          # debugging
  gem 'capybara'                        # integration tests
  gem 'capybara-email'                  # integration tests for email
  gem 'capybara-screenshot'             # for test debugging
  gem 'coveralls', require: false       # coverage analysis
  gem 'database_cleaner', '~> 1.5.0'
  gem 'factory_girl_rails'              # for creating test data
  gem 'haml-i18n-extractor'
  gem 'haml_lint'                       # Checks haml files for goodness
  gem 'haml-rails'                      # HTML templating language
  gem 'i18n-tasks'                      # adds tests for finding missing and unused translations
  gem 'jasmine'                         # javascript unit testing
  gem 'poltergeist'                     # for headless JS testing
  gem 'rspec-activemodel-mocks'
  gem 'rspec-rails'                     # unit testing framework
  gem 'rubocop', require: false
  gem 'rainbow', '< 2.2.0' # See https://github.com/sickill/rainbow/issues/44
  gem 'selenium-webdriver'
  gem 'webrat'                          # provides HTML matchers for view tests
end

group :test do
  gem 'codeclimate-test-reporter', require: false
end

group :travis do
  gem 'heroku-api'
end
