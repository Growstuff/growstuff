class Garden < ActiveRecord::Base
  attr_accessible :name, :slug, :user_id
end
