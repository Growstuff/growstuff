I18n.load_path += Dir[Rails.root.join('config', 'locales', '*.{rb,yml}')]

if Rails.env.development? || Rails.env.test?
  I18n.exception_handler = lambda do |exception, locale, key, options|
    raise "Missing translation: #{key}"
  end
end
 