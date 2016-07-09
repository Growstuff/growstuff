Growstuff::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!

  # Reload model classes when changed: otherwise Spork tests old versions.
  config.cache_classes = false

  # Configure static asset server for tests with Cache-Control for performance
  config.serve_static_files = true
  config.static_cache_control = "public, max-age=3600"

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = true

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  
  # Growstuff config
  config.action_mailer.default_url_options = { host: 'localhost:8080' }

  Growstuff::Application.configure do
    config.host = 'test.example.com'
    config.analytics_code = ''
    config.currency = 'AUD'
  end

  config.after_initialize do
    require "active_merchant/ext/paypal_bogus_gateway"
    ActiveMerchant::Billing::Base.mode = :test
    ::STANDARD_GATEWAY = ActiveMerchant::Billing::PaypalBogusGateway.new
    ::EXPRESS_GATEWAY = ActiveMerchant::Billing::PaypalBogusGateway.new
  end

end

Geocoder.configure(lookup: :test)

Geocoder::Lookup::Test.add_stub(
  "Amundsen-Scott Base, Antarctica", [
    {
      'latitude' =>         -90.0,
      'longitude' =>        0.0,
    }
  ]
)

Geocoder::Lookup::Test.add_stub(
  "Philippines", [
    {
      'latitude'     => 12.7503486,
      'longitude'    => 122.7312101,
      'address'      => 'Manila, Mnl, Philippines',
      'state'        => 'Manila',
      'state_code'   => 'Mnl',
      'country'      => 'Philippines',
      'country_code' => 'PH'
    }
  ]
)

Geocoder::Lookup::Test.add_stub(
  "Greenwich, UK", [
    {
      'latitude' =>         51.483061,
      'longitude' =>        -0.004151,
    }
  ]
)

Geocoder::Lookup::Test.add_stub(
  "Edinburgh", [
    {
      'latitude' =>         55.953252,
      'longitude' =>        -3.188267,
    }
  ]
)

# Unknown location
Geocoder::Lookup::Test.add_stub( "Tatooine", [])

Capybara.configure do |config|
  config.always_include_port = true
end
