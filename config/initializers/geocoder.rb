require 'geocodable'

Geocoder.configure(
  units: :km,
  timeout: 10,
  http_headers: {
    "User-Agent" =>
      "#{Growstuff::Application.config.user_agent} #{Growstuff::Application.config.user_agent_email}",
    "From" => Growstuff::Application.config.user_agent_email
  }
)
# This configuration takes precedence over environment/test.rb
# Reported as https://github.com/alexreisner/geocoder/issues/509
Geocoder.configure(lookup: :nominatim) if Geocoder.config.lookup != :test
