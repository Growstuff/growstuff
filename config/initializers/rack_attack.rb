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

    STATIC_FILES = /\.(css|js|map|png|jpe?g|gif|webp|avif|ico|svg|woff2?|eot|ttf|otf)$/
    NOT_PAGES = %r{^/(assets|rails/active_storage|api)(/|$)}

    # A request for a page, as a person or a crawler loads one: not a file, an image, an API call or a request a page makes
    # for its own data (such as the suggestions page fetching a season).
    def page_load?
      get? && !xhr? && !path.match?(STATIC_FILES) && !path.match?(NOT_PAGES) &&
        !path.end_with?('.json') && !env['HTTP_ACCEPT'].to_s.start_with?('application/json')
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

  # Nothing to stop on a developer's own machine, where it only gets in the way.
  self.enabled = false if Rails.env.development?

  ### Cache Config ###

  # Count requests in this process's memory, not in Rails.cache (memcached).
  # When memcached times out, the counters silently stop working and
  # crawlers are never throttled or banned.
  # Each Puma worker keeps its own counters, so the effective limits are
  # per worker.
  cache.store = ActiveSupport::Cache::MemoryStore.new(size: 8.megabytes)

  ### Throttle Config ###

  if Rails.env.production?
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

  # Slow down visitors who load pages faster than a person reads them: more than 120 pages in 5 minutes gets "Too many
  # requests" until the window passes, with no ban to wait out. Signed-in members are left alone (their member pages have
  # the throttle above), and only pages count, not images, scripts or the data a page fetches for itself.
  throttle('page_loads/ip', limit: 120, period: 5.minutes) do |req|
    req.ip if req.page_load? && !req.logged_in?
  end

  # What a blocked or slowed request is told: a page that says why and what to do, which also names the rule.
  self.blocklisted_responder = ->(request) { RackAttackPage.blocked(request) }
  self.throttled_responder = ->(request) { RackAttackPage.throttled(request) }

  ActiveSupport::Notifications.subscribe(/\A(blocklist|throttle)\.rack_attack\z/) do |_name, _start, _finish, _id, payload|
    request = payload[:request]
    Rails.logger.warn("[Rack::Attack] #{request.env['rack.attack.match_type']} #{request.env['rack.attack.matched']} " \
                      "ip=#{request.ip} path=#{request.path}")
  end
end
