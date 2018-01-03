class Product < ApplicationRecord
  #
  # Relationships
  belongs_to :account_type
  has_and_belongs_to_many :orders # rubocop:disable Rails/HasAndBelongsToMany

  #
  # Validations
  validates :paid_months, allow_nil: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :min_price, presence: true

  def to_s
    name
  end
end
