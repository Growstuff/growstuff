class Planting < ActiveRecord::Base
  extend FriendlyId
  friendly_id :planting_slug, use: :slugged

  attr_accessible :crop_id, :description, :garden_id, :planted_at, :quantity

  belongs_to :garden
  belongs_to :crop
  belongs_to :forum

  def planting_slug
    "#{owner.login_name}-#{garden.name}-#{crop.system_name}".downcase.gsub(' ', '-')
  end

  def location
    return "#{garden.owner.login_name}'s #{garden.name}"
  end

  def owner
    return garden.owner
  end
end
