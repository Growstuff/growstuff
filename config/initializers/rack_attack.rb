# frozen_string_literal: true

class Rack::Attack
  ### Throttle Config ###

  # Throttle requests to /plantings, /harvests, and /members to 10 per minute per IP
  # Includes API routes
  throttle('req/ip/restricted_routes', limit: 10, period: 1.minute) do |req|
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

  ### Custom Response Headers ###

  # Add Retry-After header to throttled responses
  self.throttled_response_retry_after_header = true
end
