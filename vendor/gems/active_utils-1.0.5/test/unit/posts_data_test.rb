require 'test_helper'
require 'active_support/core_ext/class'

class PostsDataTest < Test::Unit::TestCase

  class SSLPoster
    include PostsData

    attr_accessor :logger
  end

  def setup
    @poster = SSLPoster.new
  end

  def test_logger_warns_if_ssl_strict_disabled
    @poster.logger = stub()
    @poster.logger.expects(:warn).with("PostsDataTest::SSLPoster using ssl_strict=false, which is insecure")

    Connection.any_instance.stubs(:request)

    SSLPoster.ssl_strict = false
    @poster.raw_ssl_request(:post, "https://shopify.com", "", {})
  end

  def test_logger_no_warning_if_ssl_strict_enabled
    @poster.logger = stub()
    @poster.logger.stubs(:warn).never
    Connection.any_instance.stubs(:request)

    SSLPoster.ssl_strict = true
    @poster.raw_ssl_request(:post, "https://shopify.com", "", {})
  end
  
end
