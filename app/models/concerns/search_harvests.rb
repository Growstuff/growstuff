# frozen_string_literal: true

module SearchHarvests
  extend ActiveSupport::Concern

  included do
    searchkick merge_mappings: true,
               settings:       { number_of_shards: 1 },
               mappings:       {
                 properties: {
                   harvests_count: { type: :integer },
                   photos_count:   { type: :integer },
                   created_at:     { type: :integer },
                   harvested_at:   { type: :date }
                 }
               }

    def search_data
      {
        slug:             slug,
        quantity:         quantity,

        # crop
        crop_id:          crop_id,
        crop_name:        crop_name,
        crop_slug:        crop.slug,

        # owner
        owner_id:         owner_id,
        owner_login_name: owner_login_name,
        owner_slug:       owner_slug,
        plant_part_name:  plant_part&.name,

        # planting
        planting_id:      planting_id,
        planting_slug:    planting&.slug,

        # photo
        has_photos:       photos.size.positive?,
        thumbnail_url:    default_photo&.thumbnail_url || crop.default_photo&.thumbnail_url,

        # counts
        photos_count:     photos.count,

        # timestamps
        harvested_at:     harvested_at,
        created_at:       created_at.to_i
      }
    end

    def self.homepage_records(limit)
      search('*', limit:    limit,
                  where:    {
                    photos_count: { gt: 0 }
                  },
                  boost_by: [:created_at],
                  load:     false)
    end
  end
end
