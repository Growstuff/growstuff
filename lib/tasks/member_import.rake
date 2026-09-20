# frozen_string_literal: true

namespace :members do
  desc "Copy one member's gardens, plantings and photos from production (or SOURCE_URL) into the local database. " \
       "Usage: rake members:pull_from_production MEMBER=login_name. " \
       "Options: SOURCE_URL, DELAY=2 (seconds between requests), " \
       "ACTIVE_ONLY=true (active gardens and current plantings only), PHOTOS=false, LOCAL_EMAIL, LOCAL_PASSWORD"
  task pull_from_production: :environment do
    abort "Refusing to pull members into a production database." if Rails.env.production?
    abort "Usage: rake members:pull_from_production MEMBER=login_name" if ENV['MEMBER'].blank?

    options = {
      login_name:     ENV.fetch('MEMBER'),
      source_url:     ENV.fetch('SOURCE_URL', RemoteApiClient::DEFAULT_SOURCE_URL),
      delay:          ENV.fetch('DELAY', 2).to_f,
      photos:         ENV['PHOTOS'] != 'false',
      active_only:    ENV['ACTIVE_ONLY'] == 'true',
      local_email:    ENV.fetch('LOCAL_EMAIL', nil),
      local_password: ENV.fetch('LOCAL_PASSWORD', nil)
    }

    puts "Pulling #{options[:login_name]} from #{options[:source_url]} (#{options[:delay]}s between requests)"
    begin
      stats = MemberImportService.new(**options).call
      puts "Done: #{stats.map { |key, count| "#{count} #{key.to_s.tr('_', ' ')}" }.join(', ')}"
    rescue MemberImportService::Aborted => e
      abort "Stopped: #{e.message}"
    end
  end
end
