# frozen_string_literal: true

namespace :gbif do
  desc "Repair imported GBIF photo authors and media licences from their original records"
  task repair_photo_credits: :environment do
    GbifService.new.repair_photo_credits!
  end

  desc "Retrieve crop info from GBIF"

  task import: :environment do
    Rails.logger = Logger.new(STDOUT)
    GbifService.new.import!
  end
end
