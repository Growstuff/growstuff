class AlternateName < ActiveRecord::Base
  attr_accessible :crop_id, :name, :creator_id
  belongs_to :crop
  belongs_to :creator, :class_name => 'Member'
end
