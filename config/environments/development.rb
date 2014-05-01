Growstuff::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true

  # cache for testing/experimentation - turn off for normal dev use
  config.action_controller.perform_caching = true
  config.cache_store = :memory_store

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  # Growstuff config
  config.new_crops_request_link = "http://example.com/not-a-real-url"
  config.action_mailer.default_url_options = { :host => 'localhost:8080' }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
      :port =>           '587',
      :address =>        'smtp.mandrillapp.com',
      :user_name =>      ENV['GROWSTUFF_MANDRILL_USERNAME'],
      :password =>       ENV['GROWSTUFF_MANDRILL_APIKEY'],
      :authentication => :login
  }

  config.host = 'localhost:8080'
  config.analytics_code = ''

  config.after_initialize do
    ActiveMerchant::Billing::Base.mode = :test
    paypal_options = {
      :login =>     ENV['GROWSTUFF_PAYPAL_USERNAME'] || 'dummy',
      :password =>  ENV['GROWSTUFF_PAYPAL_PASSWORD'] || 'dummy',
      :signature => ENV['GROWSTUFF_PAYPAL_SIGNATURE'] || 'dummy'
    }
    ::STANDARD_GATEWAY = ActiveMerchant::Billing::PaypalGateway.new(paypal_options)
    ::EXPRESS_GATEWAY = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)
  end
end
