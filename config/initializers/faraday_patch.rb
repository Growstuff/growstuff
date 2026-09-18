# frozen_string_literal: true

# Compatibility shim for Searchkick / elasticsearch-transport expecting Faraday::Error::ConnectionFailed in Faraday 2.x
module Faraday
  class Error < StandardError
    ConnectionFailed = Faraday::ConnectionFailed unless defined?(ConnectionFailed)
  end
end
