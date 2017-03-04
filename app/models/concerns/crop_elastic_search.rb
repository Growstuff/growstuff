module CropElastic
  extend ActiveSupport::Concern

  included do # rubocop:disable Metrics/BlockLength
    # In order to avoid clashing between different environments,
    # use Rails.env as a part of index name (eg. development_growstuff)
    index_name [Rails.env, "growstuff"].join('_')
    settings index: { number_of_shards: 1 },
             analysis: {
               tokenizer: {
                 gs_edgeNGram_tokenizer: {
                   type: "edgeNGram", # edgeNGram: NGram match from the start of a token
                   min_gram: 3,
                   max_gram: 10,
                   # token_chars: Elasticsearch will split on characters
                   # that don't belong to any of these classes
                   token_chars: %w(letter digit)
                 }
               },
               analyzer: {
                 gs_edgeNGram_analyzer: {
                   tokenizer: "gs_edgeNGram_tokenizer",
                   filter: ["lowercase"]
                 }
               }
             } do
      mappings dynamic: 'false' do
        indexes :id, type: 'long'
        indexes :name, type: 'string', analyzer: 'gs_edgeNGram_analyzer'
        indexes :approval_status, type: 'string'
        indexes :scientific_names do
          indexes :name,
            type: 'string',
            analyzer: 'gs_edgeNGram_analyzer',
            # Disabling field-length norm (norm). If the norm option is turned on(by default),
            # higher weigh would be given for shorter fields, which in our case is irrelevant.
            norms: { enabled: false }
        end
        indexes :alternate_names do
          indexes :name, type: 'string', analyzer: 'gs_edgeNGram_analyzer'
        end
      end
    end
  end
end
