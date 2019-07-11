module PhotoCapable
  extend ActiveSupport::Concern

  included do
    has_many :photo_associations, as: :photographable, dependent: :destroy, inverse_of: :photographable
    has_many :photos, through: :photo_associations, as: :photographable

    scope :has_photos, -> { includes(:photos).where.not(photos: { id: nil }) }
  end
end
