# frozen_string_literal: true

module SearchPlantings
  extend ActiveSupport::Concern

  included do
    searchkick merge_mappings: true, mappings: {
      properties: {
        active: { type: :boolean },
        created_at: { type: :integer },
        harvests_count: { type: :integer },
        photos_count: { type: :integer },
        owner_location: { type: :text }
      }
    }

    scope :search_import, -> { includes(:owner, :crop) }

    def search_data
      {
        slug: slug,
        active: active,
        finished: finished?,
        has_photos: photos.size.positive?,
        location: location,
        percentage_grown: percentage_grown.to_i,
        planted_at: planted_at,
        planted_from: planted_from,
        quantity: quantity,
        sunniness: sunniness,

        # crops
        crop_id: crop_id,
        crop_name: crop.name,
        crop_slug: crop.slug,

        # owner
        owner_id: owner_id,
        owner_location: owner_location,
        owner_login_name: owner_login_name,
        owner_slug: owner_slug,

        # photos
        thumbnail_url: default_photo&.thumbnail_url || crop.default_photo&.thumbnail_url,
        # counts
        photos_count: photos.size,
        harvests_count: harvests_count,

        # timestamps
        created_at: created_at.to_i
      }
    end

    def self.homepage_records(limit)
      search('*', limit: limit,
                  where: {
                    photos_count: { gt: 0 }
                  },
                  boost_by: [:created_at],
                  load: false)
    end
  end
end
