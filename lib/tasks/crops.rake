# frozen_string_literal: true

namespace :crops do
  desc "Copy approved crops from production (or SOURCE_URL) into the local database, gently. " \
       "Options: SOURCE_URL, PAGE_SIZE=50 (the server may cap this), DELAY=2 (seconds between requests), " \
       "MAX_PAGES"
  task pull_from_production: :environment do
    abort "Refusing to pull crops into a production database." if Rails.env.production?

    options = {
      source_url: ENV.fetch('SOURCE_URL', RemoteApiClient::DEFAULT_SOURCE_URL),
      page_size:  ENV.fetch('PAGE_SIZE', 50).to_i,
      delay:      ENV.fetch('DELAY', 2).to_f,
      max_pages:  ENV['MAX_PAGES']&.to_i
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

  desc "Work out the medians from seed packets (row spacing, months to sow) for every crop that has packets."
  task update_seed_medians: :environment do
    Crop.update_all_seed_medians
    puts "Updated the crops with seed packets"
  end

  desc "Link crops to their EcoCrop record by scientific name, where they haven't one. Only single, sure matches are " \
       "linked; the rest are listed in a CSV for a person to choose from (see crops:link_ecocrop_from_csv). " \
       "Options: DRY_RUN=true to link nothing, REVIEW_CSV=path (default tmp/ecocrop_review.csv, or - for stdout " \
       "with the summary in lines starting #)."
  task match_ecocrop: :environment do
    dry_run = ENV['DRY_RUN'] == 'true'
    matches = EcocropMatcher.new.call
    linkable, to_review = matches.partition(&:linkable?)

    unless dry_run
      linkable.each { |match| match.crop.update_columns(ecocrop_data_id: match.record.id, updated_at: Time.current) } # rubocop:disable Rails/SkipsModelValidations
    end

    review_path = ENV.fetch('REVIEW_CSV', Rails.root.join('tmp/ecocrop_review.csv').to_s)
    csv = CSV.generate do |rows|
      rows << %w(crop_id crop_name scientific_names method candidate_ecoportcodes candidate_names chosen_ecoportcode)
      to_review.reject { |match| match.how == :none }.each do |match|
        rows << [match.crop.id, match.crop.name, match.crop.scientific_names.map(&:name).join('; '), match.how,
                 match.candidates.map(&:ecoportcode).join('; '), match.candidates.map(&:scientificname).join('; '), nil]
      end
    end

    summary = ["#{dry_run ? 'Would link' : 'Linked'} #{linkable.size} crops, " \
               "#{linkable.map(&:record).uniq.size} EcoCrop records.",
               *matches.group_by(&:how).map { |how, group| "  #{how}: #{group.size}" }]
    if review_path == '-'
      puts csv
      puts(summary.map { |line| "# #{line}" })
    else
      File.write(review_path, csv)
      puts summary, "Crops to review are in #{review_path}: fill in chosen_ecoportcode and run crops:link_ecocrop_from_csv."
    end
  end

  desc "Link crops to the EcoCrop records chosen in a reviewed CSV from crops:match_ecocrop. CSV=path. " \
       "Rows with a blank chosen_ecoportcode are skipped."
  task link_ecocrop_from_csv: :environment do
    path = ENV.fetch('CSV') { abort "Give the reviewed file as CSV=path." }
    linked = 0
    CSV.foreach(path, headers: true) do |row|
      next if row['chosen_ecoportcode'].blank?

      record = EcocropData.find_by(ecoportcode: row['chosen_ecoportcode'])
      crop = Crop.find_by(id: row['crop_id'])
      if record && crop
        crop.update_columns(ecocrop_data_id: record.id, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
        linked += 1
      else
        warn "Skipped crop #{row['crop_id']}: no crop or no EcoCrop record #{row['chosen_ecoportcode']}."
      end
    end
    puts "Linked #{linked} crops."
  end
end
