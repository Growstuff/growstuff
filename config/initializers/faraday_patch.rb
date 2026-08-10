# frozen_string_literal: true

# Compatibility shim for Faraday 2.x which removed Faraday::Error namespace
module Faraday
  class Error < StandardError
    ConnectionFailed = Faraday::ConnectionFailed
    TimeoutError = Faraday::TimeoutError
  end
end
