# frozen_string_literal: true

Searchkick.model_options = {
  settings: {
    number_of_shards:   1,
    number_of_replicas: 0
  }
}
