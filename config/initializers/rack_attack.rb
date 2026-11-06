# frozen_string_literal: true

class Rack::Attack
  class Request < ::Rack::Request
    def authenticated_user
      env['warden']&.user
    end

    def admin?
      user = authenticated_user
      user.respond_to?(:role?) && user.role?(:admin)
    end

    def logged_in?
      !authenticated_user.nil?
    end

    def rate_limit_modifier
      Rack::Attack.rate_limit_modifier(self)
    end
  end

  # Rate limit modifier based on authentication status:
  # - Admins attract only 25% of the threshold
  # - Logged in users attract only 50% of the threshold
  # - Unauthenticated visitors attract 100% of the threshold
  def self.rate_limit_modifier(req)
    user = req.respond_to?(:env) ? req.env['warden']&.user : nil
    if user.respond_to?(:role?) && user.role?(:admin)
      0.25
    elsif !user.nil?
      0.5
    else
      1.0
    end
  end

  def self.modified_limit(req, base_limit)
    (base_limit / rate_limit_modifier(req)).to_i
  end

  ### Cache Config ###

  # Count requests in this process's memory, not in Rails.cache (memcached).
  # When memcached times out, the counters silently stop working and
  # crawlers are never throttled or banned.
  # Each Puma worker keeps its own counters, so the effective limits are
  # per worker.
  cache.store = ActiveSupport::Cache::MemoryStore.new(size: 8.megabytes)

  ### Throttle Config ###

  if Rails.env.production? || Rails.env.test?
    # Throttle requests for members' data to 20 per minute per IP, on both the
    # HTML routes and their /api/v1 equivalents.
    # Rate limit modifier adjusts the threshold:
    # - admins attract only 25% of the threshold (effective limit: 80)
    # - logged in users attract only 50% of the threshold (effective limit: 40)
    # - unauthenticated visitors attract 100% of the threshold (effective limit: 20)
    restricted_routes = %r{^(/api/v1)?/(jobs|plantings|harvests|members)(/|$)}

    throttle('req/ip/restricted_routes', limit: ->(req) { modified_limit(req, 20) }, period: 1.minute) do |req|
      req.ip if req.path.match?(restricted_routes)
    end

    ### Fail2Ban Config ###

    # Block IPs that make too many requests to suspicious paths
    # After 5 "bad" requests in 10 minutes, block the IP for 1 hour
    blocklist('fail2ban/pentesters') do |req|
      Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 5, findtime: 10.minutes, bantime: 1.hour) do
        # The count for the IP is incremented if the return value is truthy.
        req.path.include?('wp-admin') ||
          req.path.include?('wp-login') ||
          req.path.include?('cgi-bin') ||
          req.path.end_with?('.php', '.asp', '.aspx', '.jsp', '.exe', '.env', '.git')
      end
    end
  end

  # Abusive services
  blocklist('block Semrush crawler') do |request|
    request.user_agent.to_s.downcase.include?('semrush')
  end

  # Block IPs listed in the BLOCKED_IPS environment variable (comma separated).
  # This lets us stop a crawler that is overloading the site without
  # committing its IP address to the repository.
  blocklist('block configured IPs') do |request|
    ENV.fetch('BLOCKED_IPS', '').split(',').map(&:strip).include?(request.ip)
  end

  # Honeypot: block IPs that request disallowed route /dont-crawl-me for 7 days (1 week)
  blocklist('fail2ban/honeypot') do |req|
    Fail2Ban.filter("honeypot-#{req.ip}", maxretry: 1, findtime: 1.day, bantime: 7.days) do
      req.path == '/dont-crawl-me' || req.path == '/dont-crawl-me/'
    end
  end

  # Ban crawlers that request more than 500 pages in a day for 1 week (7 days)
  blocklist('allow2ban/excessive_crawling') do |req|
    Allow2Ban.filter("excessive-crawling-#{req.ip}", maxretry: 500, findtime: 1.day, bantime: 1.week) do
      req.get? && !req.path.match?(%r{\.(css|js|png|jpg|jpeg|gif|ico|svg|woff2?|eot|ttf|otf)$})
    end
  end
  
  ### Custom Response Headers ###

  # Add Retry-After header to throttled responses
  self.throttled_response_retry_after_header = true
end
