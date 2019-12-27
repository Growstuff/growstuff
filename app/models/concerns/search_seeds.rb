# frozen_string_literal: true

module SearchSeeds
  extend ActiveSupport::Concern

  included do
    searchkick merge_mappings: true, mappings: {
      properties: {
        created_at:   { type: :integer },
        plant_before: { type: :text },
        photos_count: { type: :integer },
        tradable_to:  { type: :text }
      }
    }

    scope :search_import, -> { includes(:owner, :crop, :parent_planting) }

    def search_data
      {
        slug:             slug,
        crop_id:          crop_id,
        crop_name:        crop.name,
        crop_slug:        crop.slug,
        finished:         finished?,
        gmo:              gmo,
        has_photos:       photos.size.positive?,
        heirloom:         heirloom,
        location:         owner.location,
        organic:          organic,
        owner_id:         owner_id,
        owner_location:   owner_location,
        owner_login_name: owner_login_name,
        owner_slug:       owner_slug,
        parent_planting:  parent_planting,
        photos_count:     photos.size,
        plant_before:     plant_before&.to_s(:ymd),
        quantity:         quantity,
        thumbnail_url:    default_photo&.thumbnail_url || crop.default_photo&.thumbnail_url,
        tradable_to:      tradable_to,
        tradable:         tradable?,
        created_at:       created_at.to_i
      }
    end

    def self.homepage_records(limit)
      search('*', limit:    limit,
                  where:    {
                    finished: false,
                    tradable: true
                  },
                  boost_by: [:created_at],
                  load:     false)
    end
  end
end
