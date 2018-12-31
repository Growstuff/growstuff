class PlantPart < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: %i(slugged finders)

  has_many :harvests, dependent: :destroy
  has_many :crops, -> { distinct }, through: :harvests

  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end
end
