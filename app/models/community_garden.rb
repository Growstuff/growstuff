# frozen_string_literal: true

# Represents a community garden referenced from external sources (e.g. OpenStreetMap).
class CommunityGarden < ApplicationRecord
  validates :title, presence: true
  validates :osm_id, uniqueness: true, allow_blank: true

  def latitude
    return if coordinates.blank?

    coordinates.split(',').first&.strip&.to_f
  end

  def longitude
    return if coordinates.blank?

    coordinates.split(',').last&.strip&.to_f
  end
end
