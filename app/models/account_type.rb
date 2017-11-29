class AccountType < ActiveRecord::Base
  #
  # Relationships
  has_many :products

  #
  # Validations
  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end
end
