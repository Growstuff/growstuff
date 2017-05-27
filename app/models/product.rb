class Product < ActiveRecord::Base
  has_and_belongs_to_many :orders # rubocop:disable Rails/HasAndBelongsToMany
  belongs_to :account_type

  validates :paid_months,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0
    },
    allow_nil: true
  validates :min_price, presence: true

  def to_s
    name
  end
end
