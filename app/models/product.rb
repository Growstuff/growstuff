class Product < ActiveRecord::Base
  attr_accessible :description, :min_price, :name
  has_and_belongs_to_many :orders

  def to_s
    name
  end
end
