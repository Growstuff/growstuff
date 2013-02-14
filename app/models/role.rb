class Role < ActiveRecord::Base
  attr_accessible :description, :name, :members
  has_and_belongs_to_many :members
end
