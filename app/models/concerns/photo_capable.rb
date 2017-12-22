module PhotoCapable
  extend ActiveSupport::Concern

  included do
    has_many :photos, through: :photographings, as: :photographable
    has_many :photographings, as: :photographable, dependent: :destroy

    scope :has_photos, -> { includes(:photos).where.not(photos: { id: nil }) }
  end
end
