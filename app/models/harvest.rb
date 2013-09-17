class Harvest < ActiveRecord::Base
  attr_accessible :crop_id, :harvested_at, :description, :owner_id, :quantity, :units

  belongs_to :crop
  belongs_to :owner, :class_name => 'Member'

end
