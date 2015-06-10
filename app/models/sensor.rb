class Sensor < ActiveRecord::Base
  has_one :planting
  has_many :measurements
end
