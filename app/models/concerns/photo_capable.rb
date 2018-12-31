module PhotoCapable
  extend ActiveSupport::Concern

  included do
    has_many :photographings, as: :photographable, dependent: :destroy, inverse_of: :photographable
    has_many :photos, through: :photographings, as: :photographable

    scope :has_photos, -> { includes(:photos).where.not(photos: { id: nil }) }
  end
end
