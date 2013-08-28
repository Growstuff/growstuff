Geocoder.configure(
  :units => :km
)
# This configuration takes precedence over environment/test.rb
# Reported as https://github.com/alexreisner/geocoder/issues/509
if Geocoder.config.lookup != :test
  Geocoder.configure(:lookup => :nominatim)
end

