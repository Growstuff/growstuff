# frozen_string_literal: true

module SearchHarvests
  extend ActiveSupport::Concern

  included do
    searchkick merge_mappings: true,
               mappings: {
                 properties: {
                   created_at: { type: :integer },
                   harvests_count: { type: :integer },
                   photos_count: { type: :integer },
                   harvested_at: { type: :date }
                 }
               }

    scope :search_import, -> { includes(:owner, :crop, :plant_part) }

    def search_data
      {
        slug: slug,
        crop_id: crop_id,
        crop_name: crop_name,
        crop_slug: crop.slug,
        has_photos: photos.size.positive?,
        owner_id: owner_id,
        owner_slug: owner_slug,
        owner_login_name: owner_login_name,
        photos_count: photos_count,
        plant_part: plant_part&.name,
        planting_id: planting_id,
        quantity: quantity,
        thumbnail_url: default_photo&.thumbnail_url || crop.default_photo&.thumbnail_url,
        harvested_at: harvested_at,
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
