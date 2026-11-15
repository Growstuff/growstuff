# frozen_string_literal: true

namespace :climate do
  desc "Work out the frost dates and the months of weather of places someone asked to see (a new member's location, a place " \
       "viewed with none held), then those with a planting or an active garden that have none yet, " \
       "and bring the latest months up to date, using up to CLIMATE_CALL_BUDGET Open-Meteo calls (default 4500). " \
       "Run it an hour or more away from weather:update."
  task update: :environment do
    budget = Integer(ENV.fetch('CLIMATE_CALL_BUDGET', ClimateUpdater::DAILY_BUDGET))
    updater = ClimateUpdater.new(budget:, progress: method(:puts))
    done = updater.update_all
    puts "Worked out the climate of #{done} places using #{updater.calls_used.ceil} Open-Meteo calls"
  end

  desc "Ask for the climate of the place of every member who has said where they are, so climate:update fetches them first, " \
       "the most recently active first. Members in the same weather cell share a request, and cells already held are left out."
  task request_members: :environment do
    members = Member.kept.located.count
    added = ClimateRequest.record_members
    puts "#{members} located members: #{added} cells newly requested, #{ClimateRequest.count} waiting in all"
  end
end

# The name the daily schedule already runs.
namespace :frost do
  desc 'The same as climate:update'
  task update: 'climate:update'
end
