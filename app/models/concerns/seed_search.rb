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
        crop_slug: crop.slug,
        crop_name: crop.name,
        crop_id: crop_id,
        owner_id: owner_id,
        owner_name: owner.login_name,
        tradable_to: tradable_to,
        tradeable: tradable?,
        parent_planting: parent_planting,
        photos_count: photos.size,
        has_photos: photos.size.positive?,
        thumbnail_url: default_photo&.thumbnail_url,
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
