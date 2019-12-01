module PhotoCapable
  extend ActiveSupport::Concern

  included do
    has_many :photo_associations, as: :photographable, dependent: :delete_all, inverse_of: :photographable
    has_many :photos, through: :photo_associations, as: :photographable

    scope :has_photos, -> { includes(:photos).where.not(photos: { id: nil }) }

    def default_photo
      most_liked_photo
    end

    def most_liked_photo
      Rails.cache.fetch("most_liked_photo/#{model_name}/#{id}") do
        photos.order(likes_count: :desc, created_at: :desc).first
      end
    end
  end
end
