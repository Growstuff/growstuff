# frozen_string_literal: true

namespace :gardens do
  desc "Mark old gardens inactive"
  task archive: :environment do
    Planting.archive!
    Garden.archive!
  end
end

namespace :weather do
  desc "Fetch daily weather for every place with an active planting (Open-Meteo): " \
       "current days first, then history with the rest of WEATHER_CALL_BUDGET (default 4500)"
  task update: :environment do
    updater = WeatherUpdater.new(budget: Integer(ENV.fetch('WEATHER_CALL_BUDGET', WeatherUpdater::DAILY_BUDGET)))
    saved = updater.update_all
    puts "Saved #{saved} days of weather using #{updater.calls_used.ceil} Open-Meteo calls"
  end
end
