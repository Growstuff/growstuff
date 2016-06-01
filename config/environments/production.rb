Growstuff::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  config.cache_store = :dalli_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Growstuff configuration
  config.action_mailer.default_url_options = { host: 'growstuff.org' }

  config.action_mailer.smtp_settings = {
      port: '587',
      address: 'smtp.mandrillapp.com',
      user_name: ENV['GROWSTUFF_MANDRILL_USERNAME'],
      password: ENV['GROWSTUFF_MANDRILL_APIKEY'],
      domain: 'heroku.com',
      authentication: :plain
  }
  config.action_mailer.delivery_method = :smtp

  config.host = 'growstuff.org'
  config.analytics_code = <<-eos
    <script src="//static.getclicky.com/js" type="text/javascript"></script>
    <script type="text/javascript">try{ clicky.init(100594260); }catch(e){}</script>
    <noscript><p><img alt="Clicky" width="1" height="1" src="//in.getclicky.com/100594260ns.gif" /></p></noscript>
  eos

  # this config variable cannot be put in application.yml as it is needed
  # by the assets pipeline, which doesn't have access to ENV.
  config.mapbox_map_id = 'growstuff.i3n2c4ie'

  config.after_initialize do
    ActiveMerchant::Billing::Base.mode = :production
    paypal_options = {
      login: ENV['GROWSTUFF_PAYPAL_USERNAME'],
      password: ENV['GROWSTUFF_PAYPAL_PASSWORD'],
      signature: ENV['GROWSTUFF_PAYPAL_SIGNATURE']
    }
    ::STANDARD_GATEWAY = ActiveMerchant::Billing::PaypalGateway.new(paypal_options)
    ::EXPRESS_GATEWAY = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)
  end

end
