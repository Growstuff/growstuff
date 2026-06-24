# frozen_string_literal: true

# Compatibility shim for Searchkick/Faraday 2.x
# See https://github.com/ankane/searchkick/issues/1628
module Faraday
  class Error < StandardError
    ConnectionFailed = Faraday::ConnectionFailed
    TimeoutError = Faraday::TimeoutError
  end
end
