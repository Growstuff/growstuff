# frozen_string_literal: true

module SearchMembers
  extend ActiveSupport::Concern

  included do
    searchkick merge_mappings: true,
               locations:      [:member_location],
               settings:       { number_of_shards: 1, number_of_replicas: 0 },
               mappings:       {
                 properties: {
                   active:          { type: :boolean },
                   created_at:      { type: :integer },
                   harvests_count:  { type: :integer },
                   photos_count:    { type: :integer },
                   plantings_count: { type: :integer },
                   seeds_count:     { type: :integer },
                   located:         { type: :boolean }
                 }
               }

    scope :search_import, -> { confirmed.where(discarded_at: nil) }

    def search_data
      {
        login_name:           login_name,
        email:                email,
        slug:                 slug,
        location:             location,
        latitude:             latitude,
        longitude:            longitude,
        geo_location:         { lat: latitude, lon: longitude },
        located:              latitude.present? && longitude.present?,
        bio:                  bio,
        preferred_avatar_uri: preferred_avatar_uri,
        gardens_count:        gardens_count,
        harvests_count:       harvests_count,
        seeds_count:          seeds_count,
        plantings_count:      plantings_count,
        photos_count:         photos_count,
        last_sign_in_at:      last_sign_in_at,
        updated_at:           updated_at.to_i,
        created_at:           created_at.to_i
      }
    end

    def self.homepage_records(limit)
      search('*', limit:    limit,
                  where:    {
                    plantings_count: { gt: 0 }
                  },
                  boost_by: [:last_sign_in_at],
                  load:     false)
    end
  end
end
