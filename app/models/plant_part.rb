class PlantPart < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: %i(slugged finders)

  has_many :harvests
  has_many :crops, -> { distinct }, through: :harvests

  def to_s
    name
  end
end
