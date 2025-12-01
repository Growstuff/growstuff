# frozen_string_literal: true

namespace :sitemap do
  desc 'Generate sitemap, but only if it has not been generated in the last 72 hours'
  task cached_refresh: :environment do
    sitemap_file = Rails.root.join('tmp', 'sitemap_generated_at.txt')
    if File.exist?(sitemap_file)
      last_generated_at = Time.parse(File.read(sitemap_file))
      if last_generated_at > 72.hours.ago
        puts 'Sitemap has been generated within the last 72 hours. Skipping.'
        exit
      end
    end

    Rake::Task['sitemap:refresh'].invoke

    File.write(sitemap_file, Time.now.to_s)
  end
end
