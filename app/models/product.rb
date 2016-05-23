class Product < ActiveRecord::Base
  has_and_belongs_to_many :orders
  belongs_to :account_type

  validates :paid_months,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0 },
    allow_nil: true

  def to_s
    name
  end

end
