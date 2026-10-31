# frozen_string_literal: true

module PhotoCapable
  extend ActiveSupport::Concern

  included do
    has_many :photo_associations, as: :photographable, dependent: :delete_all, inverse_of: :photographable
    has_many :photos, through: :photo_associations, as: :photographable

    scope :has_photos, -> { includes(:photos).where.not(photos: { id: nil }) }

    def default_photo
      most_liked_photo
    end

    def thumbnail_url
      Rails.cache.fetch("#{cache_key_with_version}/thumbnail_url", expires_in: 8.hours) do
        df = default_photo

        if df
          df.source == 'flickr' ? df.fullsize_url : df.thumbnail_url
        elsif respond_to?(:crop) && crop.present?
          crop.thumbnail_url
        end
      end
    end

    # Chosen in Ruby when the photos are already loaded, so a page of records
    # that preloaded them doesn't ask for each one's best again.
    def most_liked_photo
      return photos.max_by { |photo| [photo.likes_count.to_i, photo.created_at] } if photos.loaded?

      photos.order(likes_count: :desc, created_at: :desc).first
    end
  end
end
