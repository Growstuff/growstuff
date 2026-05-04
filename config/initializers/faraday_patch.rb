# frozen_string_literal: true

require 'faraday'

# Faraday 2.x removed some nested constants under Faraday::Error.
# This shim provides compatibility for gems or code expecting the old structure.
module Faraday
  class Error
    ConnectionFailed = Faraday::ConnectionFailed unless const_defined?(:ConnectionFailed)
    TimeoutError = Faraday::TimeoutError unless const_defined?(:TimeoutError)
  end
end
