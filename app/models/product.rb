class Product < ActiveRecord::Base
  attr_accessible :description, :min_price, :name
  has_and_belongs_to_many :orders
end
