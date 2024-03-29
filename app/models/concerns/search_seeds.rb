# frozen_string_literal: true

module SearchSeeds
  extend ActiveSupport::Concern

  included do
    searchkick merge_mappings: true,
               settings:       { number_of_shards: 1, number_of_replicas: 0 },
               mappings:       {
                 properties: {
                   id:           { type: :integer },
                   created_at:   { type: :integer },
                   plant_before: { type: :text },
                   photos_count: { type: :integer },
                   tradable_to:  { type: :text }
                 }
               }

    def search_data
      {
        slug:,
        finished:         finished?,
        gmo:,
        active:,
        heirloom:,
        location:         owner.location,
        organic:,
        quantity:,
        plant_before:     plant_before&.to_fs(:ymd),
        tradable_to:,
        tradable:,

        # crop
        crop_id:,
        crop_name:        crop.name,
        crop_slug:        crop.slug,

        # owner
        owner_id:,
        owner_location:,
        owner_login_name:,
        owner_slug:,

        # planting
        parent_planting:,

        # counts
        photos_count:     photos.size,

        # photo
        has_photos:       photos.size.positive?,
        thumbnail_url:    default_photo&.thumbnail_url || crop.default_photo&.thumbnail_url,

        created_at:       created_at.to_i
      }
    end

    def self.homepage_records(limit)
      search('*', limit:,
                  where:    {
                    finished: false,
                    tradable: true
                  },
                  boost_by: [:created_at],
                  load:     false)
    end
  end
end
