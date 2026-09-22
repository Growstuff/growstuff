# frozen_string_literal: true

namespace :crops do
  desc "Copy approved crops from production (or SOURCE_URL) into the local database, gently. " \
       "Options: SOURCE_URL, PAGE_SIZE=50 (the server may cap this), DELAY=2 (seconds between requests), " \
       "MAX_PAGES, REINDEX=false"
  task pull_from_production: :environment do
    abort "Refusing to pull crops into a production database." if Rails.env.production?

    options = {
      source_url: ENV.fetch('SOURCE_URL', RemoteApiClient::DEFAULT_SOURCE_URL),
      page_size:  ENV.fetch('PAGE_SIZE', 50).to_i,
      delay:      ENV.fetch('DELAY', 2).to_f,
      max_pages:  ENV['MAX_PAGES']&.to_i,
      reindex:    ENV['REINDEX'] != 'false'
    }

    puts "Pulling crops from #{options[:source_url]} (#{options[:delay]}s between requests)"
    begin
      stats = CropImportService.new(**options).call
      puts "Done: #{stats.map { |key, count| "#{count} #{key.to_s.tr('_', ' ')}" }.join(', ')}"
    rescue CropImportService::Aborted => e
      abort "Stopped: #{e.message}"
    end
  end

  desc "Give crops an icon from app/assets/images/crops by their name, where they haven't one. " \
       "Varieties then follow their parent. DRY_RUN=true to only list what it would do."
  task assign_icons: :environment do
    dry_run = ENV['DRY_RUN'] == 'true'
    assigned = CropIconMatcher.new.call(dry_run:)
    assigned.each { |crop, icon| puts "#{crop.name} -> #{icon}" }
    puts "#{dry_run ? 'Would give' : 'Gave'} #{assigned.size} crops an icon."
  end
end
