class Planting < ActiveRecord::Base
  attr_accessible :crop_id, :description, :garden_id, :planted_at, :quantity

  belongs_to :garden
  belongs_to :crop

  def location
    return "#{garden.owner.login_name}'s #{garden.name}"
  end

  def owner
    return garden.owner
  end
end
