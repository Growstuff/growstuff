# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'simplecov'

# output coverage locally AND send it to coveralls
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([SimpleCov::Formatter::HTMLFormatter])

# fail if there's a significant test coverage drop
SimpleCov.maximum_coverage_drop 1

require 'spec_helper'
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
Rails.application.eager_load!

require 'capybara'
require 'capybara/rspec'
require 'selenium/webdriver'
require 'capybara-screenshot/rspec'
require 'axe-capybara'
require 'axe-rspec'

# TODO: We may want to trial options.add_argument('--disable-dev-shm-usage')      ### optional

# Required for running in the dev container
Capybara.register_driver :selenium_chrome_customised_headless do |app|
  options = Selenium::WebDriver::Options.chrome
  options.add_argument("--headless")
  options.add_argument("--no-sandbox")

  # driver = Selenium::WebDriver.for :chrome, options: options

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

# Ability to pass in flags to
if ENV["CAPYBARA_DRIVER"]
  Capybara.default_driver = ENV["CAPYBARA_DRIVER"].to_sym
  Capybara.javascript_driver = ENV["CAPYBARA_DRIVER"].to_sym
else
  Capybara.default_driver = :selenium_chrome_customised_headless
  Capybara.javascript_driver = :selenium_chrome_customised_headless
end
Capybara.enable_aria_label = true

Capybara::Screenshot.register_driver(:selenium_chrome_customised_headless) do |driver, path|
  driver.browser.save_screenshot(path)
end
Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  "screenshot_#{example.description.tr(' ', '-').gsub(%r{^.*/spec/}, '')}"
end

Capybara.app_host = 'http://localhost'
Capybara.server_port = 8081

# TODO: Find a better home.
shared_examples 'is accessible' do
  it "is accessible" do
    expect(page).to be_axe_clean
  end
end

include Warden::Test::Helpers

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("spec/features/shared_examples/**/*.rb")].sort.each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.raise_errors_for_deprecations!

  # controller specs require this to work with Devise
  # see https://github.com/plataformatec/devise/wiki/How-To%3a-Controllers-and-Views-tests-with-Rails-3-%28and-rspec%29
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.extend ControllerMacros, type: :controller

  # Allow just create(:factory) instead of needing to specify FactoryBot.create(:factory)
  config.include FactoryBot::Syntax::Methods

  # Prevent Poltergeist from fetching external URLs during feature tests
  config.before(:each, :js) do
    width = 1280
    height = 1280
    Capybara.current_session.driver.browser.manage.window.resize_to(width, height)

    if page.driver.browser.respond_to?(:url_blacklist)
      page.driver.browser.url_blacklist = [
        'gravatar.com',
        'okfn.org',
        'googlecode.com'
      ]
    end

    page.driver.browser.manage.window.maximize if page.driver.browser.respond_to?(:manage)
  end
end
