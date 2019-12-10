module HarvestSearch
  extend ActiveSupport::Concern

  included do
    searchkick

    scope :search_import, -> { includes(:owner, :crop, :plant_part) }

    def search_data
      {
        slug:          slug,
        crop_slug:     crop.slug,
        crop_name:     crop.name,
        crop_id:       crop_id,
        plant_part:    plant_part&.name,
        owner_id:      owner_id,
        owner_name:    owner.login_name,
        planting_id:   planting_id,
        photos_count:  photos.size,
        has_photos:    photos.size.positive?,
        thumbnail_url: default_photo&.thumbnail_url,
        created_at:    created_at.to_i
      }
    end

    def self.homepage_records(limit)
      self.search('*',
        limit:    limit,
        where:    {
          photos_count: { gt: 0 }
        },
        boost_by: [:created_at],
        load:     false)
    end
  end
end
