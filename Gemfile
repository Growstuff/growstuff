source 'https://rubygems.org'

gem 'bundler', '>=1.1.5'

gem 'rails', '3.2.8'

gem 'haml'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # long term, we'll probably want node.js for performance, but this will do for now as it's easier for new people to install
  gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'

#  GROWSTUFF ADDITIONS BELOW HERE

# user signup/login/etc
gem 'devise'

# for testing
group :development, :test do
  gem 'rspec-rails'
  gem 'webrat'
  gem 'watchr'
  gem 'spork', '~> 0.9.0.rc'
end
