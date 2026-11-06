# frozen_string_literal: true

Graphiti.configure do |config|
  # The API has always linked to the next page; RemoteApiClient follows links.next.
  config.pagination_links = true

  # Graphiti loads included relationships in threads outside the test environment. Each thread takes a database
  # connection, which is not worth it on a small dyno.
  config.concurrency = false
end
