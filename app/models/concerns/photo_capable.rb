# frozen_string_literal: true

module PhotoCapable
  extend ActiveSupport::Concern

  included do
    has_many :photo_associations, as: :photographable, dependent: :delete_all, inverse_of: :photographable
    has_many :photos, through: :photo_associations, as: :photographable

    scope :has_photos, -> { includes(:photos).where.not(photos: { id: nil }) }

    def default_photo
      Rails.cache.fetch("#{cache_key_with_version}/default_photo", expires_in: 8.hours) do
        most_liked_photo
      end
    end

    def thumbnail_url
      df = default_photo

      return unless df

      df.source == 'flickr' ? df.fullsize_url : df.thumbnail_url
    end

    def most_liked_photo
      photos.order(likes_count: :desc, created_at: :desc).first
    end
  end
end
