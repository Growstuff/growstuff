# frozen_string_literal: true

class PlantPart < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: %i(slugged finders)

  has_many :harvests, dependent: :destroy
  has_many :crops, -> { joins_members.distinct }, through: :harvests

  validates :name, presence: true, uniqueness: true

  scope :joins_members, -> { joins("INNER JOIN members ON members.id = harvests.owner_id") }

  def to_s
    name
  end
end
