class Harvest < ActiveRecord::Base
  attr_accessible :crop_id, :harvested_at, :notes, :owner_id, :quantity, :units
end
