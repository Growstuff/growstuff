# frozen_string_literal: true

namespace :climate do
  desc "Work out the frost dates and the months of weather of places with a planting or an active garden that have none yet, " \
       "and bring the latest months up to date, using up to CLIMATE_CALL_BUDGET Open-Meteo calls (default 4500). " \
       "Run it an hour or more away from weather:update."
  task update: :environment do
    budget = Integer(ENV.fetch('CLIMATE_CALL_BUDGET', ClimateUpdater::DAILY_BUDGET))
    updater = ClimateUpdater.new(budget:)
    done = updater.update_all
    puts "Worked out the climate of #{done} places using #{updater.calls_used.ceil} Open-Meteo calls"
  end
end

# The name the daily schedule already runs.
namespace :frost do
  desc 'The same as climate:update'
  task update: 'climate:update'
end
