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
end
