# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'
require 'openssl'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Growstuff
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    I18n.config.enforce_available_locales = true

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'UTC'
    config.active_record.default_timezone = :local

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    I18n.load_path += Dir[Rails.root.join('config', 'locales', '*.{rb,yml}')]
    I18n.default_locale = :en
    # rails will fallback to config.i18n.default_locale translation
    config.i18n.fallbacks = true
    # rails will fallback to en, no matter what is set as config.i18n.default_locale
    config.i18n.fallbacks = [:en]

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Don't try to connect to the database when precompiling assets
    config.assets.initialize_on_precompile = true

    config.generators do |g|
      g.template_engine  :haml
      g.view_specs       false
      g.controller_specs false
      g.helper           false
      g.stylesheets      false
      g.javascripts      false
    end

    # Growstuff-specific configuration variables
    config.currency = 'AUD'
    config.bot_email = ENV['GROWSTUFF_EMAIL']
    config.user_agent = 'Growstuff'
    config.user_agent_email = "info@growstuff.org"

    Gibbon::API.api_key = ENV['GROWSTUFF_MAILCHIMP_APIKEY'] || 'notarealkey'
    # API key can't be blank or tests fail
    Gibbon::API.timeout = 10
    Gibbon::API.throws_exceptions = false
    config.newsletter_list_id = ENV['GROWSTUFF_MAILCHIMP_NEWSLETTER_ID']

    # config.active_record.raise_in_transactional_callbacks = true
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '/api/v1/*', headers: :any, methods: %i(get options)
      end
    end
  end
end
