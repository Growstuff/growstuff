# frozen_string_literal: true

module SearchPhotos
  extend ActiveSupport::Concern

  included do
    searchkick merge_mappings: true,
               settings:       { number_of_shards: 1, number_of_replicas: 0 },
               mappings:       {
                 properties: {
                   title:      { type: :text },
                   created_at: { type: :integer }
                 }
               }

    def search_data
      {
        id:                     id,
        title:                  title,
        thumbnail_url:          thumbnail_url,
        fullsize_url:           fullsize_url,
        # crops
        crops:                  crops.pluck(:id),
        # likes
        liked_by_members_names: liked_by_members_names,
        # owner
        owner_id:               owner_id,
        owner_login_name:       owner_login_name,
        owner_slug:             owner_slug,
        # counts
        likes_count:            likes_count,

        created_at:             created_at.to_i
      }
    end
  end
end
