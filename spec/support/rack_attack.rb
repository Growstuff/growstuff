# frozen_string_literal: true

# Rack::Attack counts requests per IP in process memory, and every spec is the
# same IP. Left on, the "excessive crawling" ban (500 page loads) kicks in part
# way through a long run and later requests get "Forbidden". Which specs those
# are depended on the random order, and on whether spec/requests/rack_attack_spec.rb
# had already switched it off. That spec turns it on for itself.
RSpec.configure do |config|
  config.before(:suite) { Rack::Attack.enabled = false }
end
