# frozen_string_literal: true

class Rack::Attack
  ### Throttle Config ###

  if Rails.env.production?
    # Throttle requests to /plantings, /harvests, and /members to 15 per minute per IP
    # Includes API routes
    throttle('req/ip/restricted_routes', limit: 15, period: 1.minute) do |req|
      if req.path =~ %r{^/(plantings|harvests|members)(/|$)} || req.path =~ %r{^/api/v1/(plantings|harvests|members)(/|$)}
        req.ip
      end
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
