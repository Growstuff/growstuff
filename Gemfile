source 'https://rubygems.org'

gem 'bundler', '>=1.1.5'

gem 'rails', '3.2.13'
gem 'rack', '~>1.4.5'
gem 'json', '~>1.7.7'
gem 'haml'

gem 'cancan'

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
  gem 'unicorn'
  gem 'dalli'
  gem 'memcachier'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # long term, we'll probably want node.js for performance, but this will do for now as it's easier for new people to install
  gem 'therubyracer', '~> 0.10.2', :platforms => :ruby
  gem "less-rails"
  gem "twitter-bootstrap-rails", '~> 2.2.2'

  gem 'uglifier', '>= 1.0.3'

  gem 'compass-rails', '~> 1.0.3'
end

gem 'jquery-rails'
gem 'flickraw'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'
gem 'rvm-capistrano'
gem 'capistrano-ext'

# To use debugger
gem 'debugger'

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
gem 'geocoder'

# For easy calendar selection
gem 'bootstrap-datepicker-rails'

# For connecting to other services (eg Twitter)
gem 'omniauth'
gem 'omniauth-twitter'
gem 'omniauth-flickr'

# for phusion passenger (i.e. mod_rails) on the server
gem 'passenger'
gem 'rake', '>= 10.0.0'
gem 'cape', '~> 1.5.0'

gem 'diff-lcs'

group :development, :test do
  gem 'thin'
  gem 'sqlite3'
  gem 'haml-rails'
  gem 'rspec-rails', '~> 2.12.1'
  gem 'webrat'
  gem 'watchr'
  gem 'factory_girl_rails', '~> 4.0'
end
