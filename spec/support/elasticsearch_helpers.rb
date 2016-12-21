module ElasticsearchHelpers
  def sync_elasticsearch(crops)
    return unless ENV['GROWSTUFF_ELASTICSEARCH'] == "true"
    crops.each { |crop| crop.__elasticsearch__.index_document }
    Crop.__elasticsearch__.refresh_index!
  end
end

RSpec.configure do |config|
  config.include ElasticsearchHelpers

  config.before(:all) do
    Crop.__elasticsearch__.create_index! force: true if ENV['GROWSTUFF_ELASTICSEARCH'] == "true"
  end
end
