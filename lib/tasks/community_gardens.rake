# frozen_string_literal: true

namespace :community_gardens do
  desc "Import community gardens from Overpass Turbo / OpenStreetMap"
  task :import, [:bbox] => :environment do |_t, args|
    bbox = args[:bbox] || ENV['BBOX']
    CommunityGardenImportService.new(bbox: bbox).call
  end
end
