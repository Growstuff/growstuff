# frozen_string_literal: true

module SearchPlantings
  extend ActiveSupport::Concern

  included do
    searchkick merge_mappings: true,
               settings:       { number_of_shards: 1, number_of_replicas: 0 },
               mappings:       {
                 properties: {
                   active:         { type: :boolean },
                   created_at:     { type: :integer },
                   harvests_count: { type: :integer },
                   photos_count:   { type: :integer },
                   owner_location: { type: :text }
                 }
               }

    scope :search_import, -> { where("NOT (finished = true OR failed = true) OR updated_at >= ?", 2.years.ago) }

    def should_index?
      (!finished && !failed) || updated_at >= 2.years.ago
    end

    def search_data
      {
        slug:,
        active:,
        finished:                   finished?,
        has_photos:                 photos.size.positive?,
        location:,
        percentage_grown:           percentage_grown.to_i,
        planted_at:,
        planted_from:,
        planted_year:               planted_at&.year,
        quantity:,
        sunniness:,
        garden_id:,
        garden_slug:                garden&.garden_slug,
        garden_name:                garden&.name,
        description:,

        first_harvest_predicted_at:,
        finish_predicted_at:,

        # crops
        crop_id:,
        crop_name:,
        crop_slug:,
        crop_perennial:,

        # owner
        owner_id:,
        owner_location:,
        owner_login_name:,
        owner_slug:,

        # photos
        thumbnail_url:              default_photo&.thumbnail_url || crop.default_photo&.thumbnail_url,
        # counts
        photos_count:               photos.size,
        harvests_count:,

        # timestamps
        created_at:                 created_at.to_i,
        updated_at:                 updated_at.to_i
      }
    end

    def self.homepage_records(limit)
      records = []
      owners = []
      1..limit.times do
        where = {
          # Disabled for now so that more relevant plantings are
          # surfaced; even if we're falling back to crop photos.
          # photos_count: { gt: 0 },
          owner_id:     { not: owners }
        }
        one_record = search('*',
                            limit:    1,
                            where:,
                            boost_by: [:created_at],
                            load:     false).first
        return records if one_record.nil?

        owners << one_record.owner_id
        records << one_record
      end
      records
    end
  end
end
