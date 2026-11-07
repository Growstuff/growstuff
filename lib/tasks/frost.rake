# frozen_string_literal: true

namespace :frost do
  desc "Work out typical frost dates for places with an active planting that have none yet, " \
       "using up to FROST_CALL_BUDGET Open-Meteo calls (default 4500). Run it after weather:update."
  task update: :environment do
    updater = FrostUpdater.new(budget: Integer(ENV.fetch('FROST_CALL_BUDGET', FrostUpdater::DAILY_BUDGET)))
    done = updater.update_all
    puts "Worked out frost dates for #{done} places using #{updater.calls_used.ceil} Open-Meteo calls"
  end
end
