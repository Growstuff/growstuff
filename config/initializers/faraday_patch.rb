# frozen_string_literal: true

# Faraday 2.x compatibility shim for Searchkick / Elasticsearch gem
module Faraday
  class Error < StandardError
    ConnectionFailed = Faraday::ConnectionFailed unless const_defined?(:ConnectionFailed)
    TimeoutError = Faraday::TimeoutError unless const_defined?(:TimeoutError)
  end
end
