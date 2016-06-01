Growstuff::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Do not eager load code on boot.
  config.eager_load = false

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true

  # cache for testing/experimentation - turn off for normal dev use
  config.action_controller.perform_caching = false
  config.cache_store = :memory_store

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets, 
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Growstuff config
  config.action_mailer.default_url_options = { host: 'localhost:8080' }

  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.smtp_settings = {
      port: '587',
      address: 'smtp.mandrillapp.com',
      user_name: ENV['GROWSTUFF_MANDRILL_USERNAME'],
      password: ENV['GROWSTUFF_MANDRILL_APIKEY'],
      authentication: :login
  }

  config.host = 'localhost:8080'
  config.analytics_code = ''

  # this config variable cannot be put in application.yml as it is needed
  # by the assets pipeline, which doesn't have access to ENV.
  config.mapbox_map_id = 'growstuff.i3n2il6a'

  config.after_initialize do
    ActiveMerchant::Billing::Base.mode = :test
    paypal_options = {
      login: ENV['GROWSTUFF_PAYPAL_USERNAME'] || 'dummy',
      password: ENV['GROWSTUFF_PAYPAL_PASSWORD'] || 'dummy',
      signature: ENV['GROWSTUFF_PAYPAL_SIGNATURE'] || 'dummy'
    }
    ::STANDARD_GATEWAY = ActiveMerchant::Billing::PaypalGateway.new(paypal_options)
    ::EXPRESS_GATEWAY = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)
  end

  config.action_controller.action_on_unpermitted_parameters = :raise
end
