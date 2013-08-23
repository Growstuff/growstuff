class ScientificName < ActiveRecord::Base
  attr_accessible :crop_id, :scientific_name, :creator_id
  belongs_to :crop
  belongs_to :creator, :class_name => 'Member'
end
