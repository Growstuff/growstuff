# frozen_string_literal: true

namespace :gbif do
  desc "Retrieve crop info from GBIF"

  task import: :environment do
    Rails.logger = Logger.new(STDOUT)
    GbifService.new.import!
  end
end
