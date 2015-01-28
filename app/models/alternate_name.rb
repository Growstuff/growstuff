class AlternateName < ActiveRecord::Base
  belongs_to :crop
  belongs_to :creator, :class_name => 'Member'
end
