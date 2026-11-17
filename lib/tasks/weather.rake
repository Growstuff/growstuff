# frozen_string_literal: true

namespace :weather do
  desc "Fetch daily weather for every place with an active planting (Open-Meteo): " \
       "current days first, then history with the rest of WEATHER_CALL_BUDGET (default 4500)"
  task update: :environment do
    updater = WeatherUpdater.new(budget: Integer(ENV.fetch('WEATHER_CALL_BUDGET', WeatherUpdater::DAILY_BUDGET)), progress: method(:puts))
    saved = updater.update_all
    puts "Saved #{saved} days of weather using #{updater.calls_used.ceil} Open-Meteo calls"
  end

  desc "Work out the frost nights and killing days of every planting from the weather we hold, " \
       "finished ones too (the daily update does only current ones)"
  task conditions: :environment do
    plantings = Planting.where.not(planted_at: nil).joins(:garden).merge(Garden.located_for_weather).includes(:garden, crop: :parent)
    plantings.find_each { |planting| PlantingCondition.refresh(planting) }
    puts "Worked out conditions for #{plantings.count} plantings"
  end
end
