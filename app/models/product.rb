class Product < ActiveRecord::Base
  attr_accessible :description, :min_price, :name,
  :account_type_id, :paid_months

  has_and_belongs_to_many :orders
  belongs_to :account_type

  def to_s
    name
  end
end
