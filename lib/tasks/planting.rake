namespace :planting do
  desc "For all active plantings with locations, work out the current weather"
  task determine_current_weather: :environment do
    require 'open_weather'


    plantings = Planting.current.joins(:garden).where('gardens.location IS NOT NULL').order('gardens.location')
    locations = {}
    plantings.each do |planting|
      api_key = 'df8abc00e3162fbd98bc48063cc6c4b5'
      options = { units: "metric", APPID: api_key }

      locations[planting.garden.location] ||= OpenWeather::Current.city(planting.garden.location, options)

      log = PlantingWeatherLog.create(planting_id: planting.id, weather_data: locations[planting.garden.location])
      puts "Weather for #{planting.garden.location} is #{log.weather_data["main"]["temp"]} degree(s) celcius and #{log.weather_data["weather"].first["main"]}"
      sleep(2) # API Limit: 60/minute
      # Example call: http://api.openweathermap.org/data/2.5/weather?q=London,uk&appid=df8abc00e3162fbd98bc48063cc6c4b5
      # {"coord":{"lon":-0.13,"lat":51.51},"weather":[{"id":800,"main":"Clear","description":"clear sky","icon":"01d"}],"base":"stations","main":{"temp":281.83,"pressure":1025,"humidity":61,"temp_min":280.15,"temp_max":283.15},"visibility":10000,"wind":{"speed":5.7,"deg":300},"clouds":{"all":0},"dt":1491808800,"sys":{"type":1,"id":5091,"message":0.0097,"country":"GB","sunrise":1491801287,"sunset":1491850179},"id":2643743,"name":"London","cod":200}
    end
  end

end
