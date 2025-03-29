# frozen_string_literal: true

class Activity < ApplicationRecord
  extend FriendlyId
  include Ownable
  include Finishable
  include SearchActivities
  include Likeable

  belongs_to :garden, optional: true
  belongs_to :planting, optional: true

  friendly_id :activity_slug, use: %i(slugged finders)

  CATEGORIES = ["General", "Weeding", "Soil Cultivation", "Fertilizing", "Pruning", "Topical Application/Treating", "Watering"]

  validates :name, presence: true
  validates :category, inclusion: { in: CATEGORIES }, presence: true
  validates :owner, presence: true

  validates :slug, uniqueness: true

  delegate :location, :latitude, :longitude, to: :owner
  delegate :login_name, :slug, :location, to: :owner, prefix: true

  def activity_slug
    "#{owner.login_name}-#{name}-#{id}".downcase.tr(' ', '-')
  end

  def to_s
    name
  end
end
