class Planting < ActiveRecord::Base
  extend FriendlyId
  friendly_id :planting_slug, use: :slugged

  attr_accessible :crop_id, :description, :garden_id, :planted_at, :quantity,
    :planted_at_string

  belongs_to :garden
  belongs_to :crop

  delegate :default_scientific_name,
    :plantings_count,
    :to => :crop,
    :prefix => true

  def planting_slug
    "#{owner.login_name}-#{garden}-#{crop}".downcase.gsub(' ', '-')
  end

  def location
    return "#{garden.owner.login_name}'s #{garden}"
  end

  def owner
    return garden.owner
  end

  def planted_at_string
    if planted_at
      planted_at.strftime("%F")
    else
      "Not yet set"
    end
  end

  def planted_at_string=(str)
    self.planted_at = Time.parse(str)
  end
end
