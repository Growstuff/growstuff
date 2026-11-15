# frozen_string_literal: true

namespace :plantings do
  desc 'Backfill missing planting short codes'
  task backfill_short_codes: :environment do
    count = 0

    Planting.where(short_code: [nil, '']).find_each do |planting|
      planting.with_lock do
        next if planting.short_code.present?

        # Older plantings may not satisfy today's validations. Only change the
        # code and timestamp, invalidating cached cards without other callbacks.
        planting.update_columns(short_code: Planting.generate_short_code(planting.owner), updated_at: Time.current)
        count += 1
      end
    end

    puts "Backfilled short codes for #{count} plantings."
  end
end
