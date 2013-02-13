class Forum < ActiveRecord::Base
  attr_accessible :description, :name, :owner_id
end
