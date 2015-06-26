require 'geocodable'

Geocoder.configure(
  :units => :km,
  :timeout => 10,
  :http_headers => {
    "User-Agent" =>
      "#{Growstuff::Application.config.user_agent} #{Growstuff::Application.config.user_agent_email}",
    "From" => Growstuff::Application.config.user_agent_email
  }
)
# This configuration takes precedence over environment/test.rb
# Reported as https://github.com/alexreisner/geocoder/issues/509
if Geocoder.config.lookup != :test
  Geocoder.configure(:lookup => :nominatim)
end

Geocoder::Lookup::Test.add_stub(
  "Philippines", [
    {
      'latitude'     => 12.7503486,
      'longitude'    => 122.7312101,
      'address'      => 'Manila, Mnl, Philippines',
      'state'        => 'Manila',
      'state_code'   => 'Mnl',
      'country'      => 'Philippines',
      'country_code' => 'PH'
    }
  ]
)