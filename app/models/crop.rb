class Crop < ActiveRecord::Base
  extend FriendlyId
  friendly_id :system_name, use: :slugged
  attr_accessible :en_wikipedia_url, :system_name, :parent_id

  has_many :scientific_names
  has_many :plantings
  has_many :photos, :through => :plantings

  belongs_to :parent, :class_name => 'Crop'
  has_many :varieties, :class_name => 'Crop', :foreign_key => 'parent_id'

  default_scope order("lower(system_name) asc")

  validates :en_wikipedia_url,
    :format => {
      :with => /^https?:\/\/en\.wikipedia\.org\/wiki/,
      :message => 'is not a valid English Wikipedia URL'
    }

  def Crop.random
    @crop = Crop.offset(rand(Crop.count)).first
    return @crop
  end

  def to_s
    return system_name
  end

  def default_scientific_name
    if scientific_names.count > 0
      return scientific_names.first.scientific_name
    else
      return nil
    end
  end

  def plantings_count
    return plantings.count
  end

  def default_photo
    return photos.first
  end

end
