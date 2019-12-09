module HarvestSearch
  extend ActiveSupport::Concern

  included do
    searchkick

    scope :search_import, -> { includes(:owner, :crop, :plant_part) }

    def search_data
      {
        slug:        slug,
        crop_slug:   crop.slug,
        crop_name:   crop.name,
        crop_id:     crop_id,
        owner_id:    owner_id,
        planting_id: planting_id,
        thumbnail_url:       default_photo&.thumbnail_url,
        created_at:  created_at.to_i
      }
    end
  end
end
