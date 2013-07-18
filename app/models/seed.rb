class Seed < ActiveRecord::Base
  attr_accessible :owner_id, :crop_id, :description, :quantity, :plant_before
  belongs_to :crop
  belongs_to :owner, :class_name => 'Member', :foreign_key => 'owner_id'
end
