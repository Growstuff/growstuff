class Product < ActiveRecord::Base
  attr_accessible :description, :min_price, :name
end
