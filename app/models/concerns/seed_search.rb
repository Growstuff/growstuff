# frozen_string_literal: true

module SeedSearch
  extend ActiveSupport::Concern

  included do
    searchkick merge_mappings: true,
               mappings: {
                 properties: {
                   created_at: { type: :integer },
                   photos_count: { type: :integer },
                   tradable_to: { type: :text }
                 }
               }

    scope :search_import, -> { includes(:owner, :crop, :parent_planting) }

    def search_data
      {
        slug: slug,
        crop_id: crop_id,
        crop_name: crop.name,
        crop_slug: crop.slug,
        gmo: gmo,
        has_photos: photos.size.positive?,
        heirloom: heirloom,
        organic: organic,
        owner_id: owner_id,
        owner_name: owner.login_name,
        parent_planting: parent_planting,
        photos_count: photos.size,
        plant_before: plant_before,
        quantity: quantity,
        thumbnail_url: default_photo&.thumbnail_url,
        tradable_to: tradable_to,
        tradeable: tradable?,
        finished: finished?,
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
