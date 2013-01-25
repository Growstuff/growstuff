class Crop < ActiveRecord::Base
  extend FriendlyId
  friendly_id :system_name, use: :slugged
  attr_accessible :en_wikipedia_url, :system_name
  has_many :scientific_names
  has_many :plantings
  default_scope order("lower(system_name) asc")

  def Crop.random
    @crop = Crop.offset(rand(Crop.count)).first
    return @crop
  end

  def to_s
    return system_name
  end
end
