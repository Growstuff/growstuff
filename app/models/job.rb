# frozen_string_literal: true

class Job < ApplicationRecord
  extend FriendlyId
  include Ownable
  include Finishable
  include Likeable

  belongs_to :garden, optional: true
  belongs_to :planting, optional: true

  friendly_id :job_slug, use: %i(slugged finders)

  validates :name, presence: true
  validates :owner, presence: true

  validates :slug, uniqueness: true

  delegate :location, :latitude, :longitude, to: :owner
  delegate :login_name, :slug, :location, to: :owner, prefix: true

  def job_slug
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
end
