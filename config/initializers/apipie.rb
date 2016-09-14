Apipie.configure do |config|
  config.app_name                = "Growstuff"
  config.api_base_url            = "/api/v1"
  config.doc_base_url            = "/api"
  # where is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/**/*.rb"
end
