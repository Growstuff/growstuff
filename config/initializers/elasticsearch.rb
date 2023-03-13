# config/initializer/elasticsearch.rb

config = {
  transport_options: { request: { timeout: 5 } }
}
if File.exist?('config/elasticsearch.yml')
  template = ERB.new(File.new('config/elasticsearch.yml').read)
  processed = YAML.safe_load(template.result(binding))
  config.merge!(processed[Rails.env].symbolize_keys)
end

# if you choose to use elasticsearch-rails-model
Elasticsearch::Model.client = Elasticsearch::Client.new(config)
# if you choose to use elasticsearch-rails-persistence
# Elasticsearch::Persistence.client = Elasticsearch::Client.new(config)
