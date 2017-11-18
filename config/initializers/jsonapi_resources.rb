JSONAPI.configure do |config|
  # built in paginators are :none, :offset, :paged
  config.default_paginator = :offset
  config.default_page_size = 10
  config.maximum_page_size = 20
end
