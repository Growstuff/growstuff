# frozen_string_literal: true

source 'https://rubygems.org'

# Match ruby version in .ruby-version
ruby File.read('.ruby-version')

gem 'rails', '~> 8.1.0'

gem 'csv'

# Asset pipeline: Propshaft serves and fingerprints what esbuild (JavaScript)
# and Sass (CSS) build into app/assets/builds; npm supplies the front-end libraries.
gem 'propshaft'
gem 'jsbundling-rails'
gem 'cssbundling-rails'

gem 'bundler', '>= 2.4.22'

gem 'haml'
gem 'oauth', '1.1.6' # Explicitly pinned, as the maintainer does huge (400 files, 45k lines) changes in point releases - required manual plus agentic security review.

# API data
gem 'jsonapi-resources'
gem 'jsonapi-swagger'
gem 'rswag-api'
gem 'rswag-ui'

# JSON pinned until this is resolved across the ecosystem (Oct 26)
# ArgumentError: unknown keyword: create_additions (ArgumentError)
#
#     caller: /home/runner/work/growstuff/growstuff/vendor/bundle/ruby/4.0.0/gems/json-3.0.2/lib/json/common.rb:302
#     |     Parser.parse(source, options)
#                 ^^^^^^
gem 'json', '< 3'
gem 'oj' # Speeds up json

# planting and harvest predictions
# based on median values for the crop
gem 'active_median'
gem 'active_record_union'

gem 'flickraw'

gem 'cancancan'                    # for checking member privileges
gem 'csv_shaper'                   # CSV export
gem 'gibbon', '~>1.2.0'            # for Mailchimp newsletter subscriptions

gem 'pg'

gem 'active_utils'
gem 'sidekiq'

# Markdown formatting for updates etc
gem 'kramdown' # the Markdown engine Tilt picks for Haml's :markdown filter

# Pagination
gem 'will_paginate'
gem 'will_paginate-bootstrap-style'

# user signup/login/etc
gem 'devise'

# nicely formatted URLs
gem 'friendly_id'

# validates URLs
gem "validate_url"

# gravatars
gem 'gravatar-ultimate'

# For geolocation
gem 'geocoder'

# DRY-er easier bootstrap 5 forms
gem "bootstrap_form", ">= 4.5.0"

# For connecting to other services (eg Flickr)
gem 'omniauth', '~> 1.3'
gem 'omniauth-flickr', '>= 0.0.15'

# Pretty charts
gem "chartkick"


gem "hashie", ">= 3.5.3"

gem 'rake', '>= 10.0.0'

# locale based flash notices for controllers
gem "responders"

# allows soft delete. Used for members.
gem 'discard', '>= 1.2'

gem 'xmlrpc' # fixes rake error - can be removed if not needed later

gem 'puma'

gem 'rack-attack'

gem 'loofah', '>= 2.19.1'
gem 'rack-protection', '>= 2.0.1'

# Member to member messaging system
gem 'mailboxer', '>= 0.15.1'

gem 'faraday'

gem 'rack-cors'

gem 'icalendar'

# for signups as requested by email service
gem 'recaptcha'

# External APIs for data
gem "gbifrb"

gem "msgpack"

# Pinned due to RAILS_ENV=production bundle exec rake assets:precompile failing with ArgumentError: wrong number of arguments (given 1, expected 0) (ArgumentError)
# /tmp/build_8301a541/vendor/bundle/ruby/3.3.0/gems/connection_pool-3.0.2/lib/connection_pool.rb:48:in `initialize'
# /tmp/build_8301a541/vendor/bundle/ruby/3.3.0/gems/activesupport-7.2.3/lib/active_support/cache/mem_cache_store.rb:63:in `new'
gem "connection_pool", "< 3"

group :production do
  gem 'dalli'

  gem 'scout_apm' # monitoring
end

group :development do
  gem 'better_errors'
  gem 'foreman'
  gem 'letter_opener'
  gem 'listen'
end

group :development, :test do
  gem 'bullet'                  # performance tuning by finding unnecesary queries
  gem 'capybara'                # integration tests
  gem 'capybara-email'          # integration tests for email
  gem 'capybara-screenshot'     # for test debugging
  gem 'database_cleaner'
  gem 'debug', platforms: %i(mri windows), require: 'debug/prelude' # debugging
  gem 'factory_bot_rails'       # for creating test data
  gem 'faker'
  gem 'haml-rails'              # HTML templating language
  gem 'pry'
  gem 'query_diet'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-rails'             # unit testing framework
  gem 'rswag-specs'
  gem 'rubocop-capybara'
  gem 'rubocop-factory_bot'
  gem 'rubocop-rails'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'

  gem 'dotenv-rails'

  # cli utils
  gem 'haml_lint', '>= 0.25.1', require: false # Checks haml files for goodness
  gem 'i18n-tasks', require: false # adds tests for finding missing and unused translations
  gem 'rspectre', require: false # finds unused code in specs
  gem 'rubocop', require: false
end

group :test do
  gem 'axe-core-capybara'
  gem 'axe-core-rspec'
  gem "percy-capybara", "~> 5.0.0"
  gem 'rails-controller-testing'
  gem "rspec-rebound"
  gem 'selenium-webdriver'
  gem 'timecop'
  gem 'vcr'
end

gem "i18n_data", "~> 1.1"

gem "paper_trail", "~> 17.0"

gem 'aws-sdk-s3', '~> 1', '>= 1.114.0', require: false
# Resizing uploaded photos and stripping their location, with libvips
gem 'image_processing', '~> 1.14'
gem 'sitemap_generator'

gem "simplecov", "~> 1.3", group: :test, require: false
