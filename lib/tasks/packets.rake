# frozen_string_literal: true

namespace :packets do
  desc 'List the photos of seed packets whose seed has no text yet, oldest first, as JSON lines. LIMIT=n for the first n'
  # usage: rake packets:needing_ocr LIMIT=5
  task needing_ocr: :environment do
    limit = ENV.fetch('LIMIT', nil).to_i
    associations = PhotoAssociation.awaiting_text.includes(:photo).order(:photo_id, :id)
    associations = associations.limit(limit) if limit.positive?

    associations.each do |association|
      puts({ photo_id:  association.photo_id.to_s,
             seed_ids:  [association.photographable_id],
             label:     association.label,
             image_url: association.photo.fullsize_url }.to_json)
    end
  end
end
