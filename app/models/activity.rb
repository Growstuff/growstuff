# frozen_string_literal: true

class Activity < ApplicationRecord
  extend FriendlyId
  include Ownable
  include Finishable
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

  def garden_name
    garden&.name
  end

  def garden_slug
    garden&.slug
  end

  def planting_name
    planting&.crop&.name
  end

  def planting_slug
    planting&.crop&.slug
  end

  scope :active, -> { where(finished: [false, nil]) }

  def self.homepage_records(limit)
    # Get the latest activity for each owner, then return the latest 'limit' of those
    Activity.where(id: Activity.select("DISTINCT ON (owner_id) id").order("owner_id, created_at DESC"))
            .order(created_at: :desc)
            .limit(limit)
  end
end
