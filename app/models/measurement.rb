class Measurement < ActiveRecord::Base
  has_one_and_belongs_to :sensor
end
