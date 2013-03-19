class ScientificName < ActiveRecord::Base
  attr_accessible :crop_id, :scientific_name
  belongs_to :crop
end
