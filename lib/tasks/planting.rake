namespace :planting do
  desc "For all active plantings with locations, work out the current weather"
  task determine_current_weather: :environment do
    require 'open_weather'

    plantings = Planting.current.joins(:garden).where('gardens.location IS NOT NULL').order('gardens.location').limit(1000)
    locations = {}
    options = { units: "metric", APPID: ENV['GROWSTUFF_OPENWEATHER_KEY'] }
    plantings.each do |planting|
      unless locations[planting.garden.location]
        locations[planting.garden.location] = OpenWeather::Current.city(planting.garden.location, options)
        sleep(2) # API Limit: 60/minute; so we want to cool our jets a little
      end

      log = PlantingWeatherLog.create(planting_id: planting.id, weather_data: locations[planting.garden.location])

      puts [
        "Weather for #{planting.garden.location} is",
        "#{log.weather_data['main']['temp']} degree(s) celcius and",
        log.weather_data['weather'].first['main'].to_s
      ].join(" ")
    end
  end
end
