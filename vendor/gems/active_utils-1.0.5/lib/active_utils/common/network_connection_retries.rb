module ActiveMerchant
  module NetworkConnectionRetries
    DEFAULT_RETRIES = 3
    DEFAULT_CONNECTION_ERRORS = {
      EOFError          => "The remote server dropped the connection",
      Errno::ECONNRESET => "The remote server reset the connection",
      Timeout::Error    => "The connection to the remote server timed out",
      Errno::ETIMEDOUT  => "The connection to the remote server timed out"
    }

    def self.included(base)
      base.send(:attr_accessor, :retry_safe)
    end

    def retry_exceptions(options={})
      connection_errors = DEFAULT_CONNECTION_ERRORS.merge(options[:connection_exceptions] || {})

      retry_network_exceptions(options) do
        begin
          yield
        rescue Errno::ECONNREFUSED => e
          raise ActiveMerchant::RetriableConnectionError, "The remote server refused the connection"
        rescue OpenSSL::X509::CertificateError => e
          NetworkConnectionRetries.log(options[:logger], :error, e.message, options[:tag])
          raise ActiveMerchant::ClientCertificateError, "The remote server did not accept the provided SSL certificate"
        rescue *connection_errors.keys => e
          raise ActiveMerchant::ConnectionError, connection_errors[e.class]
        end
      end
    end

    private

    def retry_network_exceptions(options = {})
      retries = options[:max] || DEFAULT_RETRIES

      begin
        yield
      rescue ActiveMerchant::RetriableConnectionError => e
        retries -= 1
        retry unless retries.zero?
        NetworkConnectionRetries.log(options[:logger], :error, e.message, options[:tag])
        raise ActiveMerchant::ConnectionError, e.message
      rescue ActiveMerchant::ConnectionError => e
        retries -= 1
        retry if (options[:retry_safe] || retry_safe) && !retries.zero?
        NetworkConnectionRetries.log(options[:logger], :error, e.message, options[:tag])
        raise
      end
    end

    def self.log(logger, level, message, tag=nil)
      tag ||= self.class.to_s
      message = "[#{tag}] #{message}"
      logger.send(level, message) if logger
    end
  end
end
