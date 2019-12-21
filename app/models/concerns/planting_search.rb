# frozen_string_literal: true

module PlantingSearch
  extend ActiveSupport::Concern

  included do
    searchkick merge_mappings: true,
               mappings: {
                 properties: {
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
        active: active?,
        crop_id: crop_id,
        crop_name: crop.name,
        crop_slug: crop.slug,
        finished: finished?,
        harvests_count: harvests.size,
        has_photos: photos.size.positive?,
        location: location,
        owner_id: owner_id,
        owner_location: owner.location,
        owner_name: owner.login_name,
        owner_slug: owner.slug,
        percentage_grown: percentage_grown.to_i,
        photos_count: photos.size,
        planted_at: planted_at,
        planted_from: planted_from,
        quantity: quantity,
        sunniness: sunniness,
        thumbnail_url: default_photo&.thumbnail_url || crop.default_photo&.thumbnail_url,
        created_at: created_at.to_i
      }
    end

    def self.homepage_records(limit)
      search('*',
             limit: limit,
             where: {
               photos_count: { gt: 0 }
             },
             boost_by: [:created_at],
             load: false)
    end
  end
end
