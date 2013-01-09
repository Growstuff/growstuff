source 'https://rubygems.org'

gem 'bundler', '>=1.1.5'

gem 'rails', '3.2.11'

gem 'haml'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

group :production, :staging do
  gem 'pg'
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
  gem "twitter-bootstrap-rails", '2.1.6'

  gem 'uglifier', '>= 1.0.3'

  gem 'compass-rails', '~> 1.0.3'
end

gem 'jquery-rails'

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
# gem 'debugger'

# Markdown formatting for updates etc
gem 'bluecloth'

# user signup/login/etc
gem 'devise'

# nicely formatted URLs
gem 'friendly_id'

# gravatars
gem 'gravatar-ultimate'

# for phusion passenger (i.e. mod_rails) on the server
gem 'passenger'
gem 'rake', '>= 10.0.0'
gem 'cape', '~> 1.5.0'

# instead of webrick, use thin, which is recommended for many reasons
# eg. better on heroku, also doesn't throw spurious asset warnings

gem 'thin'

gem 'diff-lcs'

group :development, :test do
  gem 'sqlite3'
  gem 'haml-rails'
  gem 'rspec-rails'
  gem 'webrat'
  gem 'watchr'
  gem 'spork', '~> 0.9.0.rc'
end
