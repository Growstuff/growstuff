# frozen_string_literal: true

require 'ssrf_filter'

module Atproto
  # Every URL we fetch comes from something a stranger typed (a handle) or
  # published (a DID document), so requests go through SsrfFilter, which
  # refuses private and loopback addresses.
  module Http
    class Error < StandardError; end

    NETWORK_ERRORS = [SsrfFilter::Error, SystemCallError, SocketError, Timeout::Error, OpenSSL::SSL::SSLError].freeze
    USER_AGENT = 'Growstuff (https://github.com/Growstuff/growstuff)'

    module_function

    def get(url)
      response = request { SsrfFilter.get(https(url), headers: default_headers, http_options: http_options) }
      raise Error, "#{response.code} from #{url}" unless response.is_a?(Net::HTTPSuccess)

      response.body.to_s
    end

    def get_json(url)
      JSON.parse(get(url))
    rescue JSON::ParserError
      raise Error, "#{url} did not return JSON"
    end

    # Returns [parsed body, response headers, success?], so callers can read a
    # DPoP nonce out of an error response.
    def post_form(url, form, headers: {})
      response = request do
        SsrfFilter.post(https(url), headers: default_headers.merge(headers), body: URI.encode_www_form(form), http_options: http_options)
      end
      [JSON.parse(response.body.to_s), response.each_header.to_h, response.is_a?(Net::HTTPSuccess)]
    rescue JSON::ParserError
      raise Error, "#{url} did not return JSON"
    end

    def request
      yield
    rescue *NETWORK_ERRORS => e
      raise Error, e.message
    end

    def https(url)
      raise Error, "not an https URL: #{url}" unless url.to_s.start_with?('https://')

      url
    end

    def default_headers
      { 'User-Agent' => USER_AGENT, 'Content-Type' => 'application/x-www-form-urlencoded' }
    end

    def http_options
      { open_timeout: 5, read_timeout: 5 }
    end
  end
end
