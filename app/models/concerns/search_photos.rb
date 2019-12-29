# frozen_string_literal: true

module SearchPhotos
  extend ActiveSupport::Concern

  included do
    searchkick merge_mappings: true, mappings: {
      properties: {
        title:      { type: :text },
        created_at: { type: :integer }
      }
    }

    scope :search_import, -> { includes(:owner, :crops, :plantings, :harvests, :seeds, :posts) }

    def search_data
      {
        id:               id,
        title:            title,
        crops:            photo_associations.map(&:crop_id),
        owner_id:         owner_id,
        owner_login_name: owner.login_name,
        likes_count:      likes_count,
        thumbnail_url:    thumbnail_url,
        fullsize_url:     fullsize_url,
        created_at:       created_at.to_i
      }
    end
  end
end
