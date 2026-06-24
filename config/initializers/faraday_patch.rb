# frozen_string_literal: true

require 'faraday'

# The project uses Faraday 2.x, which lacks the legacy `Faraday::Error` namespace, causing `NameError` in gems like Searchkick.
# Rescuing connection issues requires `Faraday::ConnectionFailed`.
# This shim handles this by assigning constants within the `Faraday::Error` class scope.

unless Faraday::Error.const_defined?(:ConnectionFailed)
  Faraday::Error.const_set(:ConnectionFailed, Faraday::ConnectionFailed)
end

unless Faraday::Error.const_defined?(:TimeoutError)
  Faraday::Error.const_set(:TimeoutError, Faraday::TimeoutError)
end
