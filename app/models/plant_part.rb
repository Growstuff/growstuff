class PlantPart < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged

  has_many :harvests
  has_many :crops, :through => :harvests, :uniq => true

  attr_accessible :name, :slug

  def to_s
    return name
  end

  def crops
    return super.reorder('name')
  end

end
