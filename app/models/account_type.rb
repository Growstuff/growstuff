class AccountType < ActiveRecord::Base
  has_many :products

  def to_s
    name
  end
end
