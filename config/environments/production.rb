Growstuff::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

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

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Growstuff configuration
  config.new_crops_request_link = "http://growstuff.org/posts/skud-20130319-requests-for-new-crops"
  config.action_mailer.default_url_options = { :host => 'growstuff.org' }

  config.action_mailer.smtp_settings = {
      :port =>           '587',
      :address =>        'smtp.mandrillapp.com',
      :user_name =>      ENV['MANDRILL_USERNAME'],
      :password =>       ENV['MANDRILL_APIKEY'],
      :domain =>         'heroku.com',
      :authentication => :plain
  }
  config.action_mailer.delivery_method = :smtp

  Growstuff::Application.configure do
    config.site_name = "Growstuff"
    config.analytics_code = <<-eos
      <script src="//static.getclicky.com/js" type="text/javascript"></script>
      <script type="text/javascript">try{ clicky.init(100594260); }catch(e){}</script>
      <noscript><p><img alt="Clicky" width="1" height="1" src="//in.getclicky.com/100594260ns.gif" /></p></noscript>
    eos
    config.currency = 'AUD'
    config.bot_email = "noreply@growstuff.org"
  end

  config.after_initialize do
    ActiveMerchant::Billing::Base.mode = :production
    paypal_options = {
      :login =>     ENV['PAYPAL_USERNAME'],
      :password =>  ENV['PAYPAL_PASSWORD'],
      :signature => ENV['PAYPAL_SIGNATURE']
    }
    ::STANDARD_GATEWAY = ActiveMerchant::Billing::PaypalGateway.new(paypal_options)
    ::EXPRESS_GATEWAY = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)
  end

end
