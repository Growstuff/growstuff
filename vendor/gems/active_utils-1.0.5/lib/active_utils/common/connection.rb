require 'uri'
require 'net/http'
require 'net/https'
require 'benchmark'

module ActiveMerchant
  class Connection
    include NetworkConnectionRetries

    MAX_RETRIES = 3
    OPEN_TIMEOUT = 60
    READ_TIMEOUT = 60
    VERIFY_PEER = true
    RETRY_SAFE = false
    RUBY_184_POST_HEADERS = { "Content-Type" => "application/x-www-form-urlencoded" }

    attr_accessor :endpoint
    attr_accessor :open_timeout
    attr_accessor :read_timeout
    attr_accessor :verify_peer
    attr_accessor :pem
    attr_accessor :pem_password
    attr_accessor :wiredump_device
    attr_accessor :logger
    attr_accessor :tag
    attr_accessor :ignore_http_status

    def initialize(endpoint)
      @endpoint     = endpoint.is_a?(URI) ? endpoint : URI.parse(endpoint)
      @open_timeout = OPEN_TIMEOUT
      @read_timeout = READ_TIMEOUT
      @retry_safe   = RETRY_SAFE
      @verify_peer  = VERIFY_PEER
      @ignore_http_status = false
    end

    def request(method, body, headers = {})
      retry_exceptions(:max_retries => MAX_RETRIES, :logger => logger, :tag => tag) do
        begin
          info "#{method.to_s.upcase} #{endpoint}", tag

          result = nil

          realtime = Benchmark.realtime do
            result = case method
            when :get
              raise ArgumentError, "GET requests do not support a request body" if body
              http.get(endpoint.request_uri, headers)
            when :post
              debug body
              http.post(endpoint.request_uri, body, RUBY_184_POST_HEADERS.merge(headers))
            when :put
              debug body
              http.put(endpoint.request_uri, body, headers)
            when :delete
              # It's kind of ambiguous whether the RFC allows bodies
              # for DELETE requests. But Net::HTTP's delete method
              # very unambiguously does not.
              raise ArgumentError, "DELETE requests do not support a request body" if body
              http.delete(endpoint.request_uri, headers)
            else
              raise ArgumentError, "Unsupported request method #{method.to_s.upcase}"
            end
          end

          info "--> %d %s (%d %.4fs)" % [result.code, result.message, result.body ? result.body.length : 0, realtime], tag
          debug result.body
          result
        end
      end
    end

    private
    def http
      http = Net::HTTP.new(endpoint.host, endpoint.port)
      configure_debugging(http)
      configure_timeouts(http)
      configure_ssl(http)
      configure_cert(http)
      http
    end

    def configure_debugging(http)
      http.set_debug_output(wiredump_device)
    end

    def configure_timeouts(http)
      http.open_timeout = open_timeout
      http.read_timeout = read_timeout
    end

    def configure_ssl(http)
      return unless endpoint.scheme == "https"

      http.use_ssl = true

      if verify_peer
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_file     = File.dirname(__FILE__) + '/../../certs/cacert.pem'
      else
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    def configure_cert(http)
      return if pem.blank?

      http.cert = OpenSSL::X509::Certificate.new(pem)

      if pem_password
        http.key = OpenSSL::PKey::RSA.new(pem, pem_password)
      else
        http.key = OpenSSL::PKey::RSA.new(pem)
      end
    end

    def handle_response(response)
      if @ignore_http_status then
        return response.body
      else
        case response.code.to_i
        when 200...300
          response.body
        else
          raise ResponseError.new(response)
        end
      end
    end

    def debug(message, tag = nil)
      log(:debug, message, tag)
    end

    def info(message, tag = nil)
      log(:info, message, tag)
    end

    def error(message, tag = nil)
      log(:error, message, tag)
    end

    def log(level, message, tag)
      message = "[#{tag}] #{message}" if tag
      logger.send(level, message) if logger
    end
  end
end
