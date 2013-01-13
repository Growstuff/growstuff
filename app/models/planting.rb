class Planting < ActiveRecord::Base
  attr_accessible :crop_id, :description, :garden_id, :planted_at, :quantity

  belongs_to :garden
  belongs_to :crop

  def location
    return "#{garden.member.username}'s #{garden.name}"
  end

  def owner
    return garden.member
  end
end
