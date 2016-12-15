# frozen_string_literal: true
source 'https://rubygems.org'

ruby '2.3.1'

gem 'rails', '~> 4.2.7'

gem 'bundler', '>=1.1.5'

gem 'sass-rails',   '~> 5.0.4'
gem 'coffee-rails', '~> 4.1.0'
gem 'haml'

# CSS framework
gem 'bootstrap-sass', '~> 3.3.6'
gem 'font-awesome-sass'

gem 'uglifier', '~> 2.7.2' # JavaScript compressor

gem 'jquery-rails'
gem 'jquery-ui-rails', '~> 5.0.2'
gem 'js-routes' # provides access to Rails routes in Javascript
gem 'flickraw'

gem 'leaflet-rails'
gem 'leaflet-markercluster-rails'
gem 'unicorn'                      # http server
gem 'pg'
gem 'figaro'                       # for handling config via ENV variables
gem 'cancancan', '~> 1.9'          # for checking member privileges
gem 'gibbon', '~>1.2.0'            # for Mailchimp newsletter subscriptions
gem 'csv_shaper'                   # CSV export
gem 'ruby-units'                   # for unit conversion

gem 'comfortable_mexican_sofa', '~> 1.12.0' # content management system

gem 'kaminari'                     # pagination
gem 'bootstrap-kaminari-views'     # bootstrap views for kaminari

gem 'activemerchant'
gem 'active_utils'
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
gem 'omniauth-twitter'
gem 'omniauth-flickr', '>= 0.0.15'
gem 'omniauth-facebook'

# client for Elasticsearch. Elasticsearch is a flexible
# and powerful, distributed, real-time search and analytics engine.
# An example of the use in the project is fuzzy crop search.

# Project does not use semver, so we want to be in sync with the version of 
# elasticsearch we use
# See https://github.com/elastic/elasticsearch-ruby#compatibility
gem "elasticsearch-api", "~> 2.0.0"
gem "elasticsearch-model"
gem "elasticsearch-rails"

gem 'rake', '>= 10.0.0'

# API gem
gem 'jsonapi-resources'

# OAuth
gem 'doorkeeper'

group :production, :staging do
  gem 'newrelic_rpm'
  gem 'dalli'
  gem 'memcachier'
  gem 'rails_12factor' # supresses heroku plugin injection
  gem 'bonsai-elasticsearch-rails' # Integration with Bonsa-Elasticsearch on heroku
  gem 'sparkpost_rails'
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
  gem 'guard'
  gem 'guard-rspec'
end

group :development, :test do
  gem 'haml-rails'                      # HTML templating language
  gem 'rspec-rails'                     # unit testing framework
  gem 'rspec-activemodel-mocks'
  gem 'byebug'                          # debugging
  gem 'database_cleaner', '~> 1.5.0'
  gem 'webrat'                          # provides HTML matchers for view tests
  gem 'factory_girl_rails'              # for creating test data
  gem 'coveralls', require: false       # coverage analysis
  gem 'capybara'                        # integration tests
  gem 'capybara-email'                  # integration tests for email
  gem 'capybara-screenshot'             # for test debugging
  gem 'poltergeist'                     # for headless JS testing
  gem 'i18n-tasks'                      # adds tests for finding missing and unused translations
  gem 'selenium-webdriver'
  gem 'haml-i18n-extractor'
  gem "active_merchant-paypal-bogus-gateway"
  gem 'rubocop', require: false
end

group :test do
  gem 'codeclimate-test-reporter', require: false
end

group :travis do
  gem 'heroku-api'
end
