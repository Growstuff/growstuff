# frozen_string_literal: true

class UnauthorisedError < JSONAPI::Error
end
JSONAPI.configure do |config|
  # built in paginators are :none, :offset, :paged
  config.default_paginator = :offset
  config.default_page_size = 10
  config.maximum_page_size = 100
  config.exception_class_whitelist = [CanCan::AccessDenied, UnauthorisedError]
end
